import os
from textual import work
from textual.app import App, ComposeResult
from textual.containers import ScrollableContainer, Container, Grid
from textual.reactive import reactive
from textual.screen import ModalScreen
from textual.widgets import (
    Footer,
    Header,
    Label,
    Button,
    Static,
    ListView,
    ListItem,
    Log,
    OptionList,
)
from textual.worker import WorkerState

import subprocess
import time
import threading


class VersionsList(OptionList):
    version_selected = reactive(None)

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.selected_option = None

    def on_show(self):
        self.focus()

    def on_option_list_option_selected(self, event: OptionList.OptionSelected):
        self.classes = "hidden"
        self.selected_option = event.option.prompt

    def watch_version_selected(self, value):
        self.version_selected = value

    def get_version(self, versions: list):
        self.classes = ""
        self.clear_options()
        for version in versions:
            self.add_option(version)

        # todo wait for option selection

        return self.selected_option


class ConfirmationScreen(ModalScreen[bool]):
    def __init__(self, question: str) -> None:
        self._question = question
        super().__init__()

    def compose(self) -> ComposeResult:
        with Grid(id="confirmation_grid"):
            yield Label(self._question, id="question")
            yield OptionList("Yes", "No", id="confirmation_options")

    def on_option_list_option_selected(self, event: OptionList.OptionSelected):
        if event.option.prompt == "Yes":
            self.dismiss(True)
        else:
            self.dismiss(False)


class ConfigManager(App):
    """A Textual app to manage Husarion UGV robot."""

    SCREENS = {"confirmation_screen": ConfirmationScreen}
    BINDINGS = [
        ("d", "toggle_dark", "Toggle dark mode"),
        ("q", "quit", "Quit the app"),
    ]
    CSS_PATH = os.path.join(os.path.dirname(__file__), "style.css")

    log_text = reactive("")

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.last_command_output = ""

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

        yield Log(id="output_log")

        # yield ConfirmationPrompt(id="confirmation_prompt", classes="hidden")

        yield VersionsList(id="versions_list", classes="hidden")

    def on_mount(self) -> None:
        self.query_one(ListView).focus()

    def action_toggle_dark(self) -> None:
        """An action to toggle dark mode."""
        self.theme = (
            "textual-dark" if self.theme == "textual-light" else "textual-light"
        )

    def on_list_view_selected(self, event: ListView.Selected) -> None:
        id = event.item.id
        if id == "update_config":
            self.run_command("just update_config")
        elif id == "restart_driver":
            self.run_command("just restart_driver")
        elif id == "driver_logs":
            self.run_command("just driver_logs")
        elif id == "restore_default":
            self.push_screen(ConfirmationScreen("Are you sure you want to restore default configuration?"))
            # self._restore_default()
            # if self.ask_for_confirmation():
            # self._restore_default()
            # self.run_command("just restore_default")
        elif id == "list_driver_versions":
            output = self.run_command("just list_driver_versions")
            self.log_text = output.state.name
        elif id == "update_driver_version":
            self.run_command("just list_driver_versions")
            versions = self.last_command_output.split("\n")
            self.query_one("#versions_list").get_version(versions)
            self.run_command("just update_driver_version")

    def on_list_view_highlighted(self, event: ListView.Highlighted) -> None:
        event.item.scroll_visible()

    def watch_log_text(self, value: str) -> None:
        log = self.query_one(Log)
        log.write_line(value)

    # def check_prompt(self, confirmed: bool) -> None:
    #     if confirmed:
    #         self.log_text = "Restoring default configuration..."
            # self.run_command("just restore_default")

    @work(exclusive=True, thread=True)
    def run_command(self, command) -> None:
        process = subprocess.Popen(
            command,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

        self.last_command_output = ""
        while True:
            output = process.stdout.readline()

            if process.poll() is not None and output == "":
                break

            self.log_text = output
            self.last_command_output += output

    @work(exclusive=True, thread=True)
    async def _restore_default(self) -> None:
        self.push_screen(ConfirmationScreen("Are you sure you want to restore default configuration?"))
        # if await self.push_screen_wait(ConfirmationScreen("Do you like Textual?")):
        #     self.run_command("just list_driver_versions")


if __name__ == "__main__":
    app = ConfigManager()
    app.run()
