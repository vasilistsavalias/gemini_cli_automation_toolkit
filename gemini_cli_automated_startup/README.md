# Gemini CLI Workspace Toolkit

This repository is a self-contained toolkit for setting up a complete development environment for Google's official Gemini CLI on Windows.

The primary workflow is:

1. Clone this repository.
2. Run the installer script to get the official Gemini CLI.
3. Set up a custom command (`gemini_init`) to bootstrap new project workspaces that are ready for immediate use with the CLI.

---

## Table of Contents

1. [**Step 1: Clone This Toolkit**](#1-step-1-clone-this-toolkit)
2. [**Step 2: Install the Official Gemini CLI**](#2-step-2-install-the-official-gemini-cli)
3. [**Step 3: Set Up the `gemini_init` Project Creator**](#3-step-3-set-up-the-gemini_init-project-creator)
4. [**File Breakdown & Script Logic**](#4-file-breakdown--script-logic)
5. [**Usage: Creating a New Workspace**](#5-usage-creating-a-new-workspace)
6. [**Guide to Using the Official Gemini CLI**](#6-guide-to-using-the-official-gemini-cli)

---

## 1. Step 1: Clone This Toolkit

First, clone this repository to a permanent location on your machine where you keep your scripts or tools.

```powershell
# Example:
git clone <your-repository-url> C:\Users\<YourUsername>\Documents\tools\gemini-toolkit
```

---

## 2. Step 2: Install the Official Gemini CLI

This is the most important step. You must install the official `gemini` command-line tool.

1. **Open PowerShell** and navigate into the directory where you just cloned this toolkit.
2. **Run the installer script.** You must bypass the execution policy for it to run correctly.

```powershell

powershell -ExecutionPolicy Bypass -File .\install-gemini-cli.ps1

```

This script will check for prerequisites (like Node.js) and install the official `gemini` command, making it available in your terminal.

---

## 3. Step 3: Set Up the `gemini_init` Project Creator

Next, create the custom `gemini_init` command. This command builds new, ready-to-use project workspaces.

### A. Create the `gemini_init.cmd` Command

1. **Create a Command Scripts Folder**: A standard location is `C:\Users\<YourUsername>\AppData\Local\Scripts`.
2. **Add it to your System PATH**: If it's not already in your PATH, run the command below and **restart PowerShell**.

    ```powershell
    $currentPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
    $scriptsPath = "C:\Users\$env:UserName\AppData\Local\Scripts"
    [System.Environment]::SetEnvironmentVariable('PATH', "$currentPath;$scriptsPath", 'User')
    ```

3. **Create the `.cmd` file**: In your command scripts folder, create `gemini_init.cmd` with the following content. **You must edit the path** to point to where you cloned the toolkit.

    ```batch
    @echo off
    rem This path MUST point to your toolkit's location. Example:
    powershell -ExecutionPolicy Bypass -File "C:\Users\<YourUsername>\Documents\tools\gemini-toolkit\pre_setup_gemini.ps1"
    ```

---

## 4. File Breakdown & Script Logic

* `install-gemini-cli.ps1`: Installs the official Google Gemini CLI. **This is the first script you run.**
* `setup_gemini.ps1`: This is the **MAIN SCRIPT**. It contains all the core logic for creating the Python virtual environment, installing packages, and generating project files.
* `pre_setup_gemini.ps1`: This is the **WRAPPER SCRIPT**. It is a lightweight script that simply calls the main `setup_gemini.ps1` script. Your `gemini_init.cmd` command points to this wrapper.

---

## 5. Usage: Creating a New Workspace

1. Create a new, empty folder and navigate into it.
2. Run the initializer:

    ```powershell
    gemini_init
    ```

Your workspace is now built and ready for you to start using the `gemini` command within it.

---

## 6. Guide to Using the Official Gemini CLI

Your new workspace is designed for the Gemini CLI.

### Startup Modes and Parameters

* **Interactive Mode**: `gemini`
* **Else open it by specifying a Model(Can be changed later)**:

    ```powershell
    gemini --model "gemini-2.5-pro"
    ```

* **Auto-Approval ("YOLO" Mode)**: **Use with caution.(Can be changed later)**

    ```powershell
    gemini --yolo
    ```

### In-Session Commands

* **Context**: `gemini "Summarize this file for me @README.md"`
* **Slash Commands**: Use `/help`, `/clear`, `/copy`, `/tools` inside the interactive session.

### Extensions and the Model Context Protocol (MCP)

* **Getting Started + MCP**: Learn how the CLI communicates with external tools. See here: <https://www.youtube.com/watch?v=we2HwLyKYEg>
* **Extensions**: Learn how to connect the CLI to other services like Firebase or GitHub. See here: <https://www.youtube.com/watch?v=4qMYRPCUbf0>

### Creating Custom Slash Commands with TOML

You can create your own powerful, reusable slash commands to encapsulate long or complex prompts into simple shortcuts. The CLI does this using `.toml` files.

### How It Works

The Gemini CLI looks for `.toml` files in a special `commands` folder. The name of the file becomes the name of your slash command.

* **Global Commands**: Place files in `C:\Users\<YourUsername>\.gemini\commands\` to make them available everywhere.
* **Project-Specific Commands**: Place files in a `.gemini\commands\` folder inside your project's root directory to make them available only within that project.

**Example: A `/summarize` Command**

Let's create a global command that summarizes any file you provide as context.

1. **Create the file**:
    `C:\Users\<YourUsername>\.gemini\commands\summarize.toml`

2. **Add the following content** to the file:

```toml
    name = "summarize"
    description = "Summarizes the content of any file provided as context."
    template = """

    Please provide a concise, bullet-point summary of the following file content that will be given to you
    """

```

3. **Usage in the CLI**

    Now, inside any project, you can run your new command:

    ```sumup
    /summarize @./path/to/your/file.js
    ```

The CLI will execute the template, inserting the content of `file.js` into the `{{prompt}}` placeholder.

---

## Custom Command Explanations

This project includes several pre-built custom commands located in the `commands` folder. These need to be copy pasted inside the .gemini folder (example :C:\Users\USERNAME\.gemini\command.)   Here is a brief overview of their functionality:

* **/analyzer**: A command for in-depth code analysis, focusing on modularity, maintainability, and quality. It follows a structured four-phase protocol to provide well-reasoned solutions.
* **/debate_main_gemini**: This command's purpose is to read and respond to the content of a file named `opinions/gemini.md`. It's designed to be a critical thinking partner.
* **/docs**: A research agent that gathers and synthesizes technical documentation from multiple sources (official docs, Reddit, Stack Overflow, blogs) into a structured `docs.md` file.
* **/image_analyzer**: A command for detailed image analysis. It performs OCR, UI element recognition, and contextual inference to provide actionable insights, especially for screenshots of code or applications.
* **/plan_mode**: A strategic planning command that operates in a read-only mode. It follows a Socratic method of questioning to understand the user's goal before creating a detailed implementation plan.
* **/save_memory**: An automated command to save the current session's state (progress, changes, next steps) into a version-controlled markdown file in the `memory/` folder.
* **/starter**: An orientation command that runs on startup. It gathers context from git, `gemini.md` files, READMEs, and the most recent memory file to create a summary and a plan for the current session.
