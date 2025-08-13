// app/javascript/application.js

import "@hotwired/turbo-rails"
import "controllers"
import "profile_menu";

document.addEventListener('turbo:load', () => {
  const closeButtons = document.querySelectorAll('.close-flash-button');

  closeButtons.forEach(button => {
    button.addEventListener('click', () => {
      const flashMessage = button.closest('.flash-message');
      if (flashMessage) {
        flashMessage.remove();
      }
    });
  });
});