{
  user,
  ...
}:
{
  users.users.${user} = {
    name = user;
    home = "/Users/${user}";
    uid = 501;
  };

  system.primaryUser = user;

}
