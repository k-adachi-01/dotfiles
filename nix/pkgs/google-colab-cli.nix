{
  lib,
  stdenv,
  fetchurl,
  python3Packages,
}: let
  py = python3Packages;
  # Official macOS wheel bundles Arrow; avoid rebuilding the full C++ library.
  arrow =
    if stdenv.hostPlatform.system == "aarch64-darwin"
    then
      py.buildPythonPackage {
        pname = "pyarrow";
        version = "24.0.0";
        format = "wheel";
        src = fetchurl {
          url = "https://files.pythonhosted.org/packages/ad/80/d022a34ff05d2cbedd8ccf841fc1f532ecfa9eb5ed1711b56d0e0ea71fc9/pyarrow-24.0.0-cp314-cp314-macosx_12_0_arm64.whl";
          hash = "sha256:1cc9057f0319e26333b357e17f3c2c022f1a83739b48a88b25bfd5fa2dc18838";
        };
        dependencies = [py.numpy];
        pythonImportsCheck = ["pyarrow"];
      }
    else py.pyarrow;
  mimetypes = py.buildPythonPackage rec {
    pname = "jupyter-mimetypes";
    version = "0.2.0";
    format = "wheel";
    src = py.fetchPypi {
      pname = "jupyter_mimetypes";
      inherit version format;
      dist = "py3";
      python = "py3";
      hash = "sha256:e6dcd989258e3fc944365b656d9173191517e0e393bd878e97ce500e5b388527";
    };
    dependencies = with py; [arrow typing-extensions];
    pythonImportsCheck = ["jupyter_mimetypes"];
  };
  kernel = py.buildPythonPackage rec {
    pname = "jupyter-kernel-client";
    version = "0.9.0";
    format = "wheel";
    src = py.fetchPypi {
      pname = "jupyter_kernel_client";
      inherit version format;
      dist = "py3";
      python = "py3";
      hash = "sha256:77acb8f2f738d97625d6bd01ee8cf21c4d59790b7ba464108712db3870416f20";
    };
    dependencies = with py; [jupyter-client jupyter-core mimetypes requests traitlets typing-extensions websocket-client];
    pythonImportsCheck = ["jupyter_kernel_client"];
  };
in
  py.buildPythonApplication rec {
    pname = "google-colab-cli";
    version = "0.8.0";
    format = "wheel";
    src = py.fetchPypi {
      pname = "google_colab_cli";
      inherit version format;
      dist = "py3";
      python = "py3";
      hash = "sha256:5e623d0b34e6efa84ea81571d0cec60099e06aebe7ea345ec62f53e810da2ec1";
    };
    dependencies = with py; [click filelock google-auth google-auth-oauthlib html2text kernel keyring nbformat packaging prompt-toolkit pydantic pygments requests rich typer typing-extensions websocket-client];
    pythonImportsCheck = ["colab_cli.cli"];
    doInstallCheck = true;
    installCheckPhase = ''
      export HOME=$(mktemp -d)
      $out/bin/colab version
      $out/bin/colab --help > /dev/null
    '';
    meta = {
      description = "Official CLI for Google Colab runtimes";
      homepage = "https://github.com/googlecolab/google-colab-cli";
      license = lib.licenses.asl20;
      mainProgram = "colab";
      platforms = lib.platforms.unix;
    };
  }
