{ ... }:
{
  # Enable sound with pipewire
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
  };

  # Enable rtkit for real-time audio
  security.rtkit.enable = true;
}
