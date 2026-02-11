import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "display", "picker"]
  static values = {
    emojis: { type: Array, default: [
      "\u{1F3E6}", "\u{1F4B0}", "\u{1F4B3}", "\u{1F3E0}", "\u{1F697}", "\u{1F4C8}", "\u{1F48E}", "\u{1F3AF}", "\u2708\uFE0F", "\u{1F6E1}\uFE0F",
      "\u{1F4BC}", "\u{1F437}", "\u{1F393}", "\u{1F3E5}", "\u{1F4BB}", "\u{1F3E2}", "\u{1F3AE}", "\u{1F37D}\uFE0F", "\u{1F6D2}", "\u26A1"
    ]}
  }

  toggle() {
    this.pickerTarget.classList.toggle("hidden")
  }

  select(event) {
    const emoji = event.currentTarget.dataset.emoji
    this.inputTarget.value = emoji
    this.displayTarget.innerHTML = emoji
    this.displayTarget.classList.add("text-2xl")
    this.pickerTarget.classList.add("hidden")
  }

  clear() {
    this.inputTarget.value = ""
    this.displayTarget.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5 text-text-muted"><path stroke-linecap="round" stroke-linejoin="round" d="M15.182 15.182a4.5 4.5 0 0 1-6.364 0M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0ZM9.75 9.75c0 .414-.168.75-.375.75S9 10.164 9 9.75 9.168 9 9.375 9s.375.336.375.75Zm-.375 0h.008v.015h-.008V9.75Zm5.625 0c0 .414-.168.75-.375.75s-.375-.336-.375-.75.168-.75.375-.75.375.336.375.75Zm-.375 0h.008v.015h-.008V9.75Z" /></svg>`
    this.displayTarget.classList.remove("text-2xl")
    this.pickerTarget.classList.add("hidden")
  }
}
