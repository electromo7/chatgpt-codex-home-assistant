"""Tests for add-on configuration files.

Validates config.yaml schema, translation completeness,
repository.yaml structure, and Dockerfile correctness.
"""

import os
import re
import subprocess

import pytest
import yaml

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADDON_DIR = os.path.join(ROOT, "chatgpt-codex")


def load_yaml(path):
    with open(path) as f:
        return yaml.safe_load(f)


def load_yaml_via_yq(path):
    """Load YAML using yq/jq for files with HA-specific syntax.

    Home Assistant config.yaml may contain values with unquoted colons
    that trip up Python's yaml.safe_load. We parse via jq for robustness.
    """
    try:
        result = subprocess.run(
            ["yq", ".", path],
            capture_output=True, text=True, check=True,
        )
        import json
        return json.loads(result.stdout)
    except (FileNotFoundError, subprocess.CalledProcessError):
        # Fallback: read raw and fix known issues before parsing
        with open(path) as f:
            content = f.read()
        # Fix unquoted values containing colons by quoting them
        lines = []
        for line in content.splitlines():
            # Match lines like "key: value: more" (value has unquoted colon)
            m = re.match(r'^(\s*\w+:\s+)(.+:.+)$', line)
            if m and not (m.group(2).startswith('"') or m.group(2).startswith("'")):
                lines.append(f'{m.group(1)}"{m.group(2)}"')
            else:
                lines.append(line)
        return yaml.safe_load("\n".join(lines))


# ---------- config.yaml ----------


class TestConfigYaml:
    @pytest.fixture(autouse=True)
    def _load(self):
        self.config = load_yaml_via_yq(os.path.join(ADDON_DIR, "config.yaml"))

    def test_required_fields_present(self):
        required = ["name", "version", "slug", "description", "arch", "options", "schema"]
        for field in required:
            assert field in self.config, f"Missing required field: {field}"

    def test_version_is_semver(self):
        version = self.config["version"]
        assert re.match(r"^\d+\.\d+\.\d+$", version), f"Version {version} is not valid semver"

    def test_slug_format(self):
        slug = self.config["slug"]
        assert re.match(r"^[a-z0-9_]+$", slug), f"Slug '{slug}' contains invalid characters"

    def test_architectures_not_empty(self):
        assert len(self.config["arch"]) > 0

    def test_supported_architectures(self):
        valid = {"aarch64", "amd64", "armhf", "armv7", "i386"}
        for arch in self.config["arch"]:
            assert arch in valid, f"Unknown architecture: {arch}"

    def test_ingress_port_is_7681(self):
        assert self.config.get("ingress_port") == 7681

    def test_ingress_enabled(self):
        assert self.config.get("ingress") is True

    def test_options_has_api_key(self):
        assert "openai_api_key" in self.config["options"]

    def test_options_has_workspace(self):
        assert "workspace" in self.config["options"]

    def test_schema_api_key_is_password(self):
        schema = self.config["schema"]
        assert "password" in schema.get("openai_api_key", "")

    def test_schema_font_size_range(self):
        schema_val = self.config["schema"]["font_size"]
        assert "int" in schema_val
        # Verify range values are present
        assert "8" in schema_val
        assert "32" in schema_val

    def test_schema_max_sessions_range(self):
        schema_val = self.config["schema"]["max_sessions"]
        assert "int" in schema_val
        assert "1" in schema_val
        assert "5" in schema_val

    def test_schema_theme_list(self):
        schema_val = self.config["schema"]["theme"]
        assert "list" in schema_val
        assert "default" in schema_val
        assert "dark" in schema_val

    def test_volume_mappings(self):
        maps = self.config.get("map", [])
        # At minimum, share and ssl should be mapped
        map_strs = " ".join(str(m) for m in maps)
        assert "share" in map_strs
        assert "ssl" in map_strs

    def test_options_defaults_match_schema(self):
        """Verify that all options keys have corresponding schema entries."""
        options_keys = set(self.config["options"].keys())
        schema_keys = set(self.config["schema"].keys())
        assert options_keys == schema_keys, (
            f"Mismatch: options has {options_keys - schema_keys}, "
            f"schema has {schema_keys - options_keys}"
        )


# ---------- repository.yaml ----------


class TestRepositoryYaml:
    @pytest.fixture(autouse=True)
    def _load(self):
        self.repo = load_yaml(os.path.join(ROOT, "repository.yaml"))

    def test_has_name(self):
        assert "name" in self.repo

    def test_has_url(self):
        assert "url" in self.repo

    def test_url_is_github(self):
        assert self.repo["url"].startswith("https://github.com")

    def test_has_maintainer(self):
        assert "maintainer" in self.repo


# ---------- Translations ----------


class TestTranslations:
    @pytest.fixture(autouse=True)
    def _load(self):
        trans_dir = os.path.join(ADDON_DIR, "translations")
        self.translations = {}
        for fname in os.listdir(trans_dir):
            if fname.endswith(".yaml"):
                lang = fname.replace(".yaml", "")
                self.translations[lang] = load_yaml(os.path.join(trans_dir, fname))
        self.config = load_yaml_via_yq(os.path.join(ADDON_DIR, "config.yaml"))

    def test_english_translation_exists(self):
        assert "en" in self.translations

    def test_all_options_have_translations(self):
        """Every config option should have an entry in en.yaml."""
        en = self.translations["en"]
        config_options = en.get("configuration", {})
        for key in self.config["options"]:
            assert key in config_options, f"Missing English translation for option: {key}"

    def test_all_translations_have_same_keys(self):
        """All translation files should cover the same option keys."""
        if len(self.translations) < 2:
            pytest.skip("Only one translation file")
        en_keys = set(self.translations["en"].get("configuration", {}).keys())
        for lang, data in self.translations.items():
            if lang == "en":
                continue
            lang_keys = set(data.get("configuration", {}).keys())
            assert lang_keys == en_keys, (
                f"Translation '{lang}' key mismatch: "
                f"missing={en_keys - lang_keys}, extra={lang_keys - en_keys}"
            )


# ---------- Dockerfile ----------


class TestDockerfile:
    @pytest.fixture(autouse=True)
    def _load(self):
        with open(os.path.join(ADDON_DIR, "Dockerfile")) as f:
            self.content = f.read()
        self.lines = self.content.strip().splitlines()

    def test_has_from_directive(self):
        assert any(line.strip().startswith("FROM") for line in self.lines)

    def test_installs_required_packages(self):
        required = ["bash", "jq", "nodejs", "npm", "ttyd", "git", "curl"]
        for pkg in required:
            assert pkg in self.content, f"Dockerfile does not install {pkg}"

    def test_installs_codex_globally(self):
        assert "@openai/codex" in self.content

    def test_copies_run_script(self):
        assert "COPY run.sh" in self.content

    def test_uses_pipefail(self):
        assert "pipefail" in self.content

    def test_s6_service_setup(self):
        assert "s6-overlay" in self.content or "s6-rc" in self.content


# ---------- AppArmor profile ----------


class TestAppArmorProfile:
    @pytest.fixture(autouse=True)
    def _load(self):
        with open(os.path.join(ADDON_DIR, "apparmor.txt")) as f:
            self.content = f.read()

    def test_denies_shadow_read(self):
        assert "deny /etc/shadow r" in self.content

    def test_denies_passwd_write(self):
        assert "deny /etc/passwd w" in self.content

    def test_denies_sysrq(self):
        assert "deny /proc/sysrq-trigger w" in self.content

    def test_allows_share_volume(self):
        assert "/share/**" in self.content

    def test_allows_data_volume(self):
        assert "/data/**" in self.content

    def test_allows_network(self):
        assert "network inet stream" in self.content

    def test_allows_node_execution(self):
        assert "/usr/bin/node" in self.content

    def test_allows_ttyd_execution(self):
        assert "/usr/bin/ttyd" in self.content
