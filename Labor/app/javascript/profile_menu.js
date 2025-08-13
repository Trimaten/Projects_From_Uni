document.addEventListener("turbo:load", () => {
    const profileButton = document.getElementById("profile-button");
    const profileMenu = document.getElementById("profile-menu");

    if (profileButton && profileMenu) {
        const firstMenuItem = profileMenu.querySelector("a, button");

        profileButton.addEventListener("click", () => {
            const isHidden = profileMenu.classList.contains("hidden");

            if (isHidden) {
                // Show the menu with animation
                profileMenu.classList.remove("hidden");
                // Trigger reflow to enable transition
                requestAnimationFrame(() => {
                    profileMenu.classList.remove("opacity-0", "scale-95");
                    profileMenu.classList.add("opacity-100", "scale-100");
                });

                if (firstMenuItem) {
                    firstMenuItem.focus();
                }
            } else {
                // Hide the menu with animation
                profileMenu.classList.add("opacity-0", "scale-95");
                profileMenu.classList.remove("opacity-100", "scale-100");

                setTimeout(() => {
                    profileMenu.classList.add("hidden");
                }, 200); // match transition duration in ms
            }
        });

        document.addEventListener("click", (event) => {
            if (
                !profileButton.contains(event.target) &&
                !profileMenu.contains(event.target)
            ) {
                // Hide immediately without animation when clicking outside
                profileMenu.classList.add("hidden");
                profileMenu.classList.add("opacity-0", "scale-95");
                profileMenu.classList.remove("opacity-100", "scale-100");
            }
        });

        // Optional: close on Escape key
        document.addEventListener("keydown", (event) => {
            if (event.key === "Escape") {
                profileMenu.classList.add("hidden");
                profileMenu.classList.add("opacity-0", "scale-95");
                profileMenu.classList.remove("opacity-100", "scale-100");
                profileButton.focus(); // return focus to button
            }
        });
    }
});
