use std::{
    env,
    ffi::OsString,
    io::{self},
    path::{Path, PathBuf},
    process::{Command, Output},
    sync::mpsc::{self, Receiver},
    thread,
    time::Duration,
};

use crossterm::{
    event::{self, Event, KeyCode, KeyEvent, KeyModifiers},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{
    backend::CrosstermBackend,
    layout::{Constraint, Direction, Layout},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, List, ListItem, ListState, Paragraph, Wrap},
    Frame, Terminal,
};
use serde_json::Value;

#[derive(Clone, Copy, PartialEq, Eq)]
enum BranchKind {
    New,
    Local,
    Remote,
}

#[derive(Clone)]
struct Branch {
    kind: BranchKind,
    name: String,
}

#[derive(Clone, Copy, PartialEq, Eq)]
enum Screen {
    Branches,
    Action,
    Name,
}

struct App {
    herdr: OsString,
    workspace_id: String,
    repo: PathBuf,
    branches: Vec<Branch>,
    query: String,
    selected: usize,
    chosen: Option<Branch>,
    screen: Screen,
    action: usize,
    branch_name: String,
    status: Option<String>,
    error: Option<String>,
    fetch: Option<Receiver<Result<(), String>>>,
    done: bool,
}

impl App {
    fn new(herdr: OsString, workspace_id: String, repo: PathBuf) -> Result<Self, String> {
        let branches = load_branches(&repo)?;
        Ok(Self {
            herdr,
            workspace_id,
            repo,
            branches,
            query: String::new(),
            selected: 0,
            chosen: None,
            screen: Screen::Branches,
            action: 0,
            branch_name: String::new(),
            status: None,
            error: None,
            fetch: None,
            done: false,
        })
    }

    fn filtered_indices(&self) -> Vec<usize> {
        let query = self.query.to_lowercase();
        self.branches
            .iter()
            .enumerate()
            .filter(|(_, branch)| query.is_empty() || branch.name.to_lowercase().contains(&query))
            .map(|(index, _)| index)
            .collect()
    }

    fn normalize_selection(&mut self) {
        let len = self.filtered_indices().len();
        self.selected = self.selected.min(len.saturating_sub(1));
    }

    fn check_fetch(&mut self) {
        let result = self
            .fetch
            .as_ref()
            .and_then(|receiver| receiver.try_recv().ok());
        let Some(result) = result else {
            return;
        };

        self.fetch = None;
        match result {
            Ok(()) => match load_branches(&self.repo) {
                Ok(branches) => {
                    self.branches = branches;
                    self.normalize_selection();
                    self.status = Some("Remote branches refreshed".into());
                    self.error = None;
                }
                Err(error) => self.error = Some(error),
            },
            Err(error) => {
                self.status = None;
                self.error = Some(error);
            }
        }
    }

    fn start_fetch(&mut self) {
        if self.fetch.is_some() {
            return;
        }

        let repo = self.repo.clone();
        let (sender, receiver) = mpsc::channel();
        thread::spawn(move || {
            let result = run_git(&repo, &["fetch", "--all", "--prune"]).map(|_| ());
            let _ = sender.send(result);
        });
        self.fetch = Some(receiver);
        self.status = Some("Fetching all remotes…".into());
        self.error = None;
    }

    fn handle_key(&mut self, key: KeyEvent) {
        if self.error.is_some() {
            self.error = None;
        }

        match self.screen {
            Screen::Branches => self.handle_branches_key(key),
            Screen::Action => self.handle_action_key(key),
            Screen::Name => self.handle_name_key(key),
        }
    }

    fn handle_branches_key(&mut self, key: KeyEvent) {
        match key.code {
            KeyCode::Esc => self.done = true,
            KeyCode::Up => self.selected = self.selected.saturating_sub(1),
            KeyCode::Down => {
                let len = self.filtered_indices().len();
                if self.selected + 1 < len {
                    self.selected += 1;
                }
            }
            KeyCode::Enter => {
                let indices = self.filtered_indices();
                let Some(index) = indices.get(self.selected) else {
                    return;
                };
                let branch = self.branches[*index].clone();
                self.chosen = Some(branch.clone());
                if branch.kind == BranchKind::New {
                    self.branch_name.clear();
                    self.screen = Screen::Name;
                } else {
                    self.action = 0;
                    self.screen = Screen::Action;
                }
            }
            KeyCode::Backspace => {
                self.query.pop();
                self.selected = 0;
            }
            KeyCode::Char('r') if key.modifiers.contains(KeyModifiers::CONTROL) => {
                self.start_fetch();
            }
            KeyCode::Char(character)
                if key.modifiers.is_empty() || key.modifiers == KeyModifiers::SHIFT =>
            {
                self.query.push(character);
                self.selected = 0;
            }
            _ => {}
        }
    }

    fn handle_action_key(&mut self, key: KeyEvent) {
        match key.code {
            KeyCode::Esc => self.screen = Screen::Branches,
            KeyCode::Left | KeyCode::Up => self.action = self.action.saturating_sub(1),
            KeyCode::Right | KeyCode::Down | KeyCode::Tab => self.action = (self.action + 1).min(1),
            KeyCode::Enter if self.action == 0 => self.checkout_chosen(),
            KeyCode::Enter => {
                self.branch_name.clear();
                self.screen = Screen::Name;
            }
            _ => {}
        }
    }

    fn handle_name_key(&mut self, key: KeyEvent) {
        match key.code {
            KeyCode::Esc => {
                self.screen = if self
                    .chosen
                    .as_ref()
                    .is_some_and(|branch| branch.kind == BranchKind::New)
                {
                    Screen::Branches
                } else {
                    Screen::Action
                };
            }
            KeyCode::Backspace => {
                self.branch_name.pop();
            }
            KeyCode::Enter => {
                let branch_name = self.branch_name.trim().to_owned();
                if branch_name.is_empty() {
                    self.error = Some("Branch name is required".into());
                    return;
                }
                let base = self
                    .chosen
                    .as_ref()
                    .map(|branch| {
                        if branch.kind == BranchKind::New {
                            "HEAD"
                        } else {
                            branch.name.as_str()
                        }
                    })
                    .unwrap_or("HEAD")
                    .to_owned();
                self.create_worktree(&branch_name, Some(&base));
            }
            KeyCode::Char(character)
                if key.modifiers.is_empty() || key.modifiers == KeyModifiers::SHIFT =>
            {
                self.branch_name.push(character);
            }
            _ => {}
        }
    }

    fn checkout_chosen(&mut self) {
        let Some(branch) = self.chosen.clone() else {
            return;
        };

        match branch.kind {
            BranchKind::Local => self.create_worktree(&branch.name, None),
            BranchKind::Remote => {
                let local_name = branch
                    .name
                    .split_once('/')
                    .map_or(branch.name.as_str(), |(_, name)| name)
                    .to_owned();
                if local_branch_exists(&self.repo, &local_name) {
                    self.create_worktree(&local_name, None);
                } else {
                    self.create_worktree(&local_name, Some(&branch.name));
                }
            }
            BranchKind::New => {}
        }
    }

    fn create_worktree(&mut self, branch: &str, base: Option<&str>) {
        self.status = Some("Creating worktree…".into());
        self.error = None;

        let mut command = Command::new(&self.herdr);
        command.args([
            "worktree",
            "create",
            "--workspace",
            &self.workspace_id,
            "--branch",
            branch,
            "--focus",
        ]);
        if let Some(base) = base {
            command.args(["--base", base]);
        }

        match command.output() {
            Ok(output) if output.status.success() => self.done = true,
            Ok(output) => {
                self.status = None;
                self.error = Some(output_message(output));
            }
            Err(error) => {
                self.status = None;
                self.error = Some(format!("Failed to run Herdr: {error}"));
            }
        }
    }
}

fn main() {
    let command = env::args().nth(1).unwrap_or_default();
    if let Err(error) = run(&command) {
        eprintln!("{error}");
        if command == "picker" {
            eprintln!("\nPress Enter to close…");
            let _ = io::stdin().read_line(&mut String::new());
        }
        std::process::exit(1);
    }
}

fn run(command: &str) -> Result<(), String> {
    match command {
        "open" => open_picker(),
        "picker" => run_picker(),
        _ => Err("Usage: herdr-worktree-picker {open|picker}".into()),
    }
}

fn open_picker() -> Result<(), String> {
    let herdr = env::var_os("HERDR_BIN_PATH").unwrap_or_else(|| "herdr".into());
    let plugin = env::var("HERDR_PLUGIN_ID").unwrap_or_else(|_| "herdr-worktree-picker".into());
    let mut command = Command::new(herdr);
    command.args([
        "plugin",
        "pane",
        "open",
        "--plugin",
        &plugin,
        "--entrypoint",
        "picker",
    ]);
    if let Ok(pane_id) = env::var("HERDR_PANE_ID") {
        command.args(["--env", &format!("HERDR_SOURCE_PANE_ID={pane_id}")]);
    }

    let output = command.output().map_err(|error| error.to_string())?;
    if output.status.success() {
        Ok(())
    } else {
        Err(output_message(output))
    }
}

fn run_picker() -> Result<(), String> {
    let herdr = env::var_os("HERDR_BIN_PATH").unwrap_or_else(|| "herdr".into());
    let workspace_id = find_workspace_id(&herdr)?;
    let repo = find_repo(&herdr)?;
    let mut app = App::new(herdr, workspace_id, repo)?;

    enable_raw_mode().map_err(|error| error.to_string())?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen).map_err(|error| error.to_string())?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend).map_err(|error| error.to_string())?;

    let result = run_event_loop(&mut terminal, &mut app);

    disable_raw_mode().map_err(|error| error.to_string())?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen).map_err(|error| error.to_string())?;
    terminal.show_cursor().map_err(|error| error.to_string())?;
    result
}

fn run_event_loop(
    terminal: &mut Terminal<CrosstermBackend<io::Stdout>>,
    app: &mut App,
) -> Result<(), String> {
    while !app.done {
        app.check_fetch();
        terminal
            .draw(|frame| draw(frame, app))
            .map_err(|error| error.to_string())?;
        if event::poll(Duration::from_millis(100)).map_err(|error| error.to_string())? {
            if let Event::Key(key) = event::read().map_err(|error| error.to_string())? {
                app.handle_key(key);
            }
        }
    }
    Ok(())
}

fn draw(frame: &mut Frame, app: &App) {
    let areas = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),
            Constraint::Min(5),
            Constraint::Length(3),
        ])
        .split(frame.area());

    let title = match app.screen {
        Screen::Branches => " Worktree branch ",
        Screen::Action => " Worktree action ",
        Screen::Name => " New branch ",
    };
    let header = match app.screen {
        Screen::Branches => Paragraph::new(format!("Search: {}", app.query)),
        Screen::Action => Paragraph::new(
            app.chosen
                .as_ref()
                .map(|branch| format!("Selected: {}", branch.name))
                .unwrap_or_default(),
        ),
        Screen::Name => Paragraph::new(format!("Branch name: {}", app.branch_name)),
    }
    .block(Block::default().title(title).borders(Borders::ALL));
    frame.render_widget(header, areas[0]);

    match app.screen {
        Screen::Branches => draw_branches(frame, areas[1], app),
        Screen::Action => draw_actions(frame, areas[1], app),
        Screen::Name => draw_name_help(frame, areas[1], app),
    }

    let footer = if let Some(error) = &app.error {
        Paragraph::new(error.as_str())
            .style(Style::default().fg(Color::Red))
            .wrap(Wrap { trim: true })
    } else if let Some(status) = &app.status {
        Paragraph::new(status.as_str()).style(Style::default().fg(Color::Yellow))
    } else {
        let help = match app.screen {
            Screen::Branches => {
                "↑↓ select • type to search • Ctrl-R fetch • Enter continue • Esc close"
            }
            Screen::Action => "←→ select • Enter continue • Esc back",
            Screen::Name => "Enter create • Esc back",
        };
        Paragraph::new(help).style(Style::default().fg(Color::DarkGray))
    }
    .block(Block::default().borders(Borders::ALL));
    frame.render_widget(footer, areas[2]);
}

fn draw_branches(frame: &mut Frame, area: ratatui::layout::Rect, app: &App) {
    let indices = app.filtered_indices();
    let items = indices
        .iter()
        .map(|index| {
            let branch = &app.branches[*index];
            let (badge, color) = match branch.kind {
                BranchKind::New => (" NEW    ", Color::Green),
                BranchKind::Local => (" LOCAL  ", Color::Blue),
                BranchKind::Remote => (" REMOTE ", Color::Magenta),
            };
            ListItem::new(Line::from(vec![
                Span::styled(
                    badge,
                    Style::default().fg(color).add_modifier(Modifier::BOLD),
                ),
                Span::raw(&branch.name),
            ]))
        })
        .collect::<Vec<_>>();
    let mut state = ListState::default();
    if !items.is_empty() {
        state.select(Some(app.selected));
    }
    let list = List::new(items)
        .block(Block::default().borders(Borders::ALL))
        .highlight_style(
            Style::default()
                .bg(Color::DarkGray)
                .add_modifier(Modifier::BOLD),
        )
        .highlight_symbol("› ");
    frame.render_stateful_widget(list, area, &mut state);
}

fn draw_actions(frame: &mut Frame, area: ratatui::layout::Rect, app: &App) {
    let checkout = if app.action == 0 {
        "● Checkout directly"
    } else {
        "○ Checkout directly"
    };
    let create = if app.action == 1 {
        "● Create new branch from base"
    } else {
        "○ Create new branch from base"
    };
    let text = vec![
        Line::from(""),
        Line::from(Span::styled(
            checkout,
            if app.action == 0 {
                Style::default()
                    .fg(Color::Cyan)
                    .add_modifier(Modifier::BOLD)
            } else {
                Style::default()
            },
        )),
        Line::from(""),
        Line::from(Span::styled(
            create,
            if app.action == 1 {
                Style::default()
                    .fg(Color::Cyan)
                    .add_modifier(Modifier::BOLD)
            } else {
                Style::default()
            },
        )),
    ];
    frame.render_widget(
        Paragraph::new(text).block(Block::default().borders(Borders::ALL)),
        area,
    );
}

fn draw_name_help(frame: &mut Frame, area: ratatui::layout::Rect, app: &App) {
    let base = app
        .chosen
        .as_ref()
        .map(|branch| {
            if branch.kind == BranchKind::New {
                "HEAD"
            } else {
                branch.name.as_str()
            }
        })
        .unwrap_or("HEAD");
    let text = vec![
        Line::from(""),
        Line::from(vec![
            Span::styled("Base: ", Style::default().fg(Color::DarkGray)),
            Span::raw(base),
        ]),
        Line::from(""),
        Line::from("Type the name for the new local branch."),
    ];
    frame.render_widget(
        Paragraph::new(text).block(Block::default().borders(Borders::ALL)),
        area,
    );
}

fn find_workspace_id(herdr: &OsString) -> Result<String, String> {
    if let Ok(workspace_id) = env::var("HERDR_WORKSPACE_ID") {
        return Ok(workspace_id);
    }

    let pane_id = env::var("HERDR_SOURCE_PANE_ID")
        .or_else(|_| env::var("HERDR_PANE_ID"))
        .map_err(|_| "Herdr did not provide a workspace context".to_string())?;
    let value = herdr_json(herdr, &["pane", "get", &pane_id])?;
    value
        .pointer("/result/pane/workspace_id")
        .and_then(Value::as_str)
        .map(ToOwned::to_owned)
        .ok_or_else(|| "Could not determine the current Herdr workspace".to_string())
}

fn find_repo(herdr: &OsString) -> Result<PathBuf, String> {
    let pane_id = env::var("HERDR_SOURCE_PANE_ID")
        .or_else(|_| env::var("HERDR_PANE_ID"))
        .ok();
    let cwd = if let Some(pane_id) = pane_id {
        let value = herdr_json(herdr, &["pane", "get", &pane_id])?;
        value
            .pointer("/result/pane/foreground_cwd")
            .or_else(|| value.pointer("/result/pane/cwd"))
            .and_then(Value::as_str)
            .map(ToOwned::to_owned)
    } else {
        let workspace = env::var("HERDR_WORKSPACE_ID")
            .map_err(|_| "Could not determine the current Herdr workspace".to_string())?;
        let value = herdr_json(herdr, &["pane", "list", "--workspace", &workspace])?;
        value
            .pointer("/result/panes")
            .and_then(Value::as_array)
            .and_then(|panes| {
                panes
                    .iter()
                    .find(|pane| pane.get("focused").and_then(Value::as_bool) == Some(true))
                    .or_else(|| panes.first())
            })
            .and_then(|pane| pane.get("foreground_cwd").or_else(|| pane.get("cwd")))
            .and_then(Value::as_str)
            .map(ToOwned::to_owned)
    }
    .ok_or_else(|| "Could not determine the current workspace directory".to_string())?;

    let output = run_git(Path::new(&cwd), &["rev-parse", "--show-toplevel"])?;
    Ok(PathBuf::from(output.trim()))
}

fn herdr_json(herdr: &OsString, args: &[&str]) -> Result<Value, String> {
    let output = Command::new(herdr)
        .args(args)
        .output()
        .map_err(|error| error.to_string())?;
    if !output.status.success() {
        return Err(output_message(output));
    }
    serde_json::from_slice(&output.stdout).map_err(|error| error.to_string())
}

fn load_branches(repo: &Path) -> Result<Vec<Branch>, String> {
    let mut branches = vec![Branch {
        kind: BranchKind::New,
        name: "Create new branch from current HEAD".into(),
    }];

    let locals = run_git(
        repo,
        &[
            "for-each-ref",
            "--sort=refname",
            "--format=%(refname:short)",
            "refs/heads",
        ],
    )?;
    branches.extend(
        locals
            .lines()
            .filter(|line| !line.is_empty())
            .map(|name| Branch {
                kind: BranchKind::Local,
                name: name.into(),
            }),
    );

    let remotes = run_git(
        repo,
        &[
            "for-each-ref",
            "--sort=refname",
            "--format=%(refname:short)%09%(symref)",
            "refs/remotes",
        ],
    )?;
    branches.extend(remotes.lines().filter_map(|line| {
        let (name, symbolic) = line.split_once('\t').unwrap_or((line, ""));
        symbolic.is_empty().then(|| Branch {
            kind: BranchKind::Remote,
            name: name.into(),
        })
    }));

    Ok(branches)
}

fn local_branch_exists(repo: &Path, branch: &str) -> bool {
    Command::new("git")
        .arg("-C")
        .arg(repo)
        .args([
            "show-ref",
            "--verify",
            "--quiet",
            &format!("refs/heads/{branch}"),
        ])
        .status()
        .is_ok_and(|status| status.success())
}

fn run_git(repo: &Path, args: &[&str]) -> Result<String, String> {
    let output = Command::new("git")
        .arg("-C")
        .arg(repo)
        .args(args)
        .output()
        .map_err(|error| error.to_string())?;
    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).trim().to_owned())
    } else {
        Err(output_message(output))
    }
}

fn output_message(output: Output) -> String {
    let stderr = String::from_utf8_lossy(&output.stderr).trim().to_owned();
    if !stderr.is_empty() {
        stderr
    } else {
        let stdout = String::from_utf8_lossy(&output.stdout).trim().to_owned();
        if stdout.is_empty() {
            format!("Command failed with {}", output.status)
        } else {
            stdout
        }
    }
}
