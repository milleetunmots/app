function isCalendlyEvent(e) {
  return e.origin === "https://calendly.com" && e.data.event?.startsWith("calendly.");
}

window.addEventListener("message", function(e) {
  if (isCalendlyEvent(e)) {
    console.log("Calendly Event:", e.data.event);
    console.log("Calendly Event:", e.data.payload);
  }
});
