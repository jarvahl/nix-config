{ fetchFromGitHub, python3Packages }:

with python3Packages;
buildPythonApplication {
  pname = "pi-gateway";
  version = "0.2.2";
  pyproject = true;

  src = fetchFromGitHub {
    hash = "sha256-221KJKHKiYb4bm1BD+22t9GLoLWzWDSFxyBFbjvfDe0=";
    owner = "jarvahl";
    repo = "pi-gateway";
    rev = "c5926d3";
  };

  postPatch = ''
    substituteInPlace pi_gateway/cli.py \
      --replace-fail '    await telegram.notify_lifecycle(lifecycle_message)' "" \
      --replace-fail '            await telegram.notify_lifecycle("🔴 Pi gateway disconnected.")' '            pass'
    substituteInPlace pi_gateway/telegram_bot.py \
      --replace-fail '        working = await message.reply_text("⏳ Pi is working...")' '        working = None'
  '';

  nativeBuildInputs = [ hatchling ];
  dependencies = [
    prompt-toolkit
    python-telegram-bot
    pyyaml
  ];
}
