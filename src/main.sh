#!/bin/bash

function stripColors {
  echo "${1}" | sed 's/\x1b\[[0-9;]*m//g'
}

function hasPrefix {
  case ${2} in
    "${1}"*)
      true
      ;;
    *)
      false
      ;;
  esac
}

function parseInputs {
  # Required inputs
  if [ "${INPUT_USE_TERRAGRUNT}" != "true" ] && [ "${INPUT_TF_ACTIONS_VERSION}" != "" ]; then
    tfVersion=${INPUT_TF_ACTIONS_VERSION}
  elif [ "${INPUT_USE_TERRAGRUNT}" == "true" ] && [ "${INPUT_TG_ACTIONS_VERSION}" != "" ] && [ "${INPUT_TF_ACTIONS_VERSION}" != "" ]; then
    tfVersion=${INPUT_TF_ACTIONS_VERSION}
    tgVersion=${INPUT_TG_ACTIONS_VERSION}
  else
    echo "At least one version input is missing"
    exit 1
  fi

  if [ "${INPUT_TF_ACTIONS_SUBCOMMAND}" != "" ]; then
    tfSubcommand=${INPUT_TF_ACTIONS_SUBCOMMAND}
  else
    echo "Input terraform_subcommand cannot be empty"
    exit 1
  fi

  # Optional inputs
  tfWorkingDir="."
  if [ "${INPUT_TF_ACTIONS_WORKING_DIR}" != "" ] || [ "${INPUT_TF_ACTIONS_WORKING_DIR}" != "." ]; then
    tfWorkingDir=${INPUT_TF_ACTIONS_WORKING_DIR}
  fi

  tfComment=0
  if [ "${INPUT_TF_ACTIONS_COMMENT}" == "1" ] || [ "${INPUT_TF_ACTIONS_COMMENT}" == "true" ]; then
    tfComment=1
  fi
}

function installTerraform {
  urltf="https://releases.hashicorp.com/terraform/${tfVersion}/terraform_${tfVersion}_linux_amd64.zip"
  urltg="https://github.com/gruntwork-io/terragrunt/releases/download/v${tgVersion}/terragrunt_linux_amd64"

  echo "Downloading Terraform v${tfVersion}"
  if ! curl -s -S -L -o /tmp/terraform_${tfVersion} ${urltf}; then
    echo "Failed to download Terraform v${tfVersion}"
    exit 1
  fi
  echo "Successfully downloaded Terraform v${tfVersion}"

  echo "Unzipping Terraform v${tfVersion}"
  unzip -d /usr/local/bin /tmp/terraform_${tfVersion} &> /dev/null
  if [ "${?}" -ne 0 ]; then
    echo "Failed to unzip Terraform v${tfVersion}"
    exit 1
  fi
  echo "Successfully unzipped Terraform v${tfVersion}"

  if [ "${INPUT_USE_TERRAGRUNT}" == "true" ]; then
    echo "Downloading Terragrunt v${tgVersion}"
    if ! curl -s -S -L -o /tmp/terragrunt ${urltg}; then
      echo "Failed to download Terragrunt v${tgVersion}"
      exit 1
    fi
    echo "Successfully downloaded Terragrunt v${tgVersion}"
    echo "Moving Terragrunt v${tgVersion} to system PATH"
    mv /tmp/terragrunt /usr/local/bin/ && chmod +x /usr/local/bin/terragrunt
    if [ "${?}" -ne 0 ]; then
      echo "Failed to move Terragrunt v${tgVersion} to system PATH"
      exit 1
    fi
    echo "Successfully moved Terragrunt v${tgVersion} to system PATH"
  else
    echo "Skipping Terragrunt installation"
  fi
}

function main {
  # Source the other files to gain access to their functions
  scriptDir=$(dirname ${0})
  source ${scriptDir}/terraform_fmt.sh || exit 1
  source ${scriptDir}/terraform_init.sh || exit 1
  source ${scriptDir}/terraform_validate.sh || exit 1
  source ${scriptDir}/terraform_plan.sh || exit 1
  source ${scriptDir}/terraform_apply.sh || exit 1
  source ${scriptDir}/terraform_output.sh || exit 1

  parseInputs
  cd ${GITHUB_WORKSPACE}/${tfWorkingDir}

  case "${tfSubcommand}" in
    fmt)
      installTerraform
      terraformFmt "${*}"
      ;;
    init)
      installTerraform
      terraformInit "${*}"
      ;;
    validate)
      installTerraform
      terraformValidate "${*}"
      ;;
    plan)
      installTerraform
      terraformPlan "${*}"
      ;;
    apply)
      installTerraform
      terraformApply "${*}"
      ;;
    output)
      installTerraform
      terraformOutput "${*}"
      ;;
    *)
      echo "Error: Must provide a valid value for terraform_subcommand"
      exit 1
      ;;
  esac
}

main "${*}"
