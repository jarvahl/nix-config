{ fetchFromGitHub, python3Packages }:

with python3Packages;
buildPythonApplication {
  pname = "pi-gateway";
  version = "0.2.2";
  pyproject = true;

  src = fetchFromGitHub {
    hash = "sha256-HBPDK/EjJM+LNfM6ypqtGgD1e/kWAaaCH1ihXhHVbQs=";
    owner = "jarvahl";
    repo = "pi-gateway";
    rev = "48f1b52";
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
