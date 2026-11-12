from pathlib import Path
import secrets

path = Path(".env")
with path.open("x") as output:
    output.write(Path(".env.example").read_text().replace("replace-with-random-password", secrets.token_hex(24)))
path.chmod(0o600)
print("Created .env; existing files are never overwritten")
