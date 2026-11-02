{ fetchFromGitHub, python3Packages }:

with python3Packages;
buildPythonApplication {
  pname = "pi-gateway";
  version = "0.2.2";
  pyproject = true;

  src = fetchFromGitHub {
    hash = "sha256-oQw94Q04swySty0Zl7muR04OfA5zDslIo+J1WtPRpkY=";
    owner = "jarvahl";
    repo = "pi-gateway";
    rev = "a807c26";
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
