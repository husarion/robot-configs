import os
from textual import work
from textual.app import App, ComposeResult
from textual.containers import ScrollableContainer, Grid
from textual.reactive import reactive
from textual.screen import ModalScreen, Screen
from textual.widgets import (
    Footer,
    Header,
    Label,
    ListView,
    ListItem,
    Log,
    OptionList,
    LoadingIndicator,
)
from textual.worker import WorkerState

import subprocess
import time
import threading
import re


class CommandHandler(Log):
    log_text = reactive("")

    def watch_log_text(self, value: str) -> None:
        self.write_line(value)

    @work(exclusive=True, thread=True)
    def run_command(self, command) -> None:
        process = subprocess.Popen(
            command,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

        while True:
            output = process.stdout.readline()

            if process.poll() is not None and output == "":
                break

            self.log_text = output

        if process.returncode != 0:
            self.log_text = f"Failed to execute command: {command}"
            for line in process.stderr:
                self.log_text = line

        self.log_text = "---"


class ConfirmationScreen(ModalScreen[bool]):
    def __init__(self, question: str) -> None:
        self._question = question
        super().__init__()

    def compose(self) -> ComposeResult:
        with Grid(id="grid"):
            yield Label(self._question, id="question")
            yield OptionList("Yes", "No", id="options")

    def on_option_list_option_selected(self, event: OptionList.OptionSelected) -> None:
        if event.option.prompt == "Yes":
            self.dismiss(True)
        else:
            self.dismiss(False)


class SelectionScreen(ModalScreen[str]):
    BINDINGS = [
        ("escape", "app.pop_screen", "Return to the previous screen"),
    ]

    def __init__(self, list_title, version_list: list[str]) -> None:
        super().__init__()
        self._list_title = list_title
        self._version_list = version_list

    def compose(self) -> ComposeResult:
        with Grid(id="grid"):
            yield Label(self._list_title, id="title")
            yield OptionList()

    def on_mount(self) -> None:
        option_list = self.query_one(OptionList)
        for version in self._version_list:
            option_list.add_option(version)

        option_list.focus()

    def on_option_list_option_selected(self, event: OptionList.OptionSelected) -> None:
        self.dismiss(event.option.prompt)


class DriverLogsScreen(Screen):
    BINDINGS = [
        ("escape", "app.pop_screen", "Back"),
    ]

    def compose(self):
        yield Footer(id="footer")
        yield CommandHandler(id="driver_logs")

    def on_screen_resume(self):
        self.log_text = "Driver logs"
        self.query_one(CommandHandler).run_command("just driver_logs -f")

    def on_screen_suspend(self):
        # todo: cancel the worker
        self.notify("Suspending")
        # self.workers.cancel_node(DriverLogsScreen)


class ConfigManager(App):
    """A Textual app to manage Husarion UGV robot."""

    BINDINGS = [
        ("q", "quit", "Quit the app"),
        ("d", "toggle_dark", "Toggle dark mode"),
        ("t", "testing", "Test"),
    ]
    CSS_PATH = os.path.join(os.path.dirname(__file__), "style.tcss")

    log_text = reactive("")

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

    def compose(self) -> ComposeResult:
        """Create child widgets for the app."""
        yield Header()
        yield Footer(id="footer")

        with ScrollableContainer(id="command_list"):
            yield ListView(
                ListItem(Label("Update Configuration"), id="update_config"),
                ListItem(Label("Restart Driver"), id="restart_driver"),
                ListItem(Label("Driver Logs"), id="driver_logs"),
                ListItem(Label("Restore Default Configuration"), id="restore_default"),
                ListItem(Label("List Driver Versions"), id="list_driver_versions"),
                ListItem(Label("Update Driver Version"), id="update_driver_version"),
            )

        yield CommandHandler(id="output_log")

    def on_mount(self) -> None:
        self.query_one(ListView).focus()
        self.install_screen(DriverLogsScreen(), "driver_logs_screen")

    def action_toggle_dark(self) -> None:
        """An action to toggle dark mode."""
        self.theme = (
            "textual-dark" if self.theme == "textual-light" else "textual-light"
        )

    @work
    async def on_list_view_selected(self, event: ListView.Selected) -> None:
        id = event.item.id
        command_loger = self.query_one(CommandHandler)
        if id == "update_config":
            command_loger.run_command("just update_config")
        elif id == "restart_driver":
            command_loger.run_command("just restart_driver")
        elif id == "driver_logs":
            self.push_screen("driver_logs_screen")
        elif id == "restore_default":
            if await self.push_screen_wait(
                ConfirmationScreen("Restore default configuration?")
            ):
                command_loger.run_command("just restore_default")
        elif id == "list_driver_versions":
            ros_distro = await self.push_screen_wait(
                SelectionScreen("Choose ROS Distro", ["humble", "jazzy"])
            )
            command_loger.run_command(f"just list_driver_versions {ros_distro}")
        elif id == "update_driver_version":
            await self._update_driver_version()

    def on_list_view_highlighted(self, event: ListView.Highlighted) -> None:
        event.item.scroll_visible()

    def watch_log_text(self, value: str) -> None:
        log = self.query_one(Log)
        log.write_line(value)

    async def run_command_sync(self, command) -> str:
        output = subprocess.run(
            command,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

        return output.stdout

    async def _update_driver_version(self) -> None:
        ros_distro = await self.push_screen_wait(
            SelectionScreen("Choose ROS Distro", ["humble", "jazzy"])
        )

        output = await self.run_command_sync(f"just list_driver_versions {ros_distro}")

        versions = output.split("\n")
        # filter out the versions, and invert list order
        versions = [
            version
            for version in versions[::-1]
            if re.search(r"\d+\.\d+\.\d+-\d{8}", version)
        ]
        version = await self.push_screen_wait(
            SelectionScreen("Choose version", versions)
        )

        if version:
            self.query_one(CommandHandler).run_command(
                f"just update_driver_version {version}"
            )


if __name__ == "__main__":
    app = ConfigManager()
    app.run()
