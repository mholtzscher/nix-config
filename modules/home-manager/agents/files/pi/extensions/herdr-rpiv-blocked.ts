import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type RpivBlockedEvent = {
  active: boolean;
};

export default function (pi: ExtensionAPI) {
  pi.events.on("rpiv:ask-user:blocked", (event: RpivBlockedEvent) => {
    pi.events.emit("herdr:blocked", {
      active: event.active,
      label: "Waiting for questionnaire",
    });
  });
}
