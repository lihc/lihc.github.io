document.addEventListener('DOMContentLoaded', () => {
    const showMenus = document.getElementById('show-menus');
    const navbar = document.getElementById('navbar');

    showMenus.addEventListener('click', () => {
        navbar.classList.add('is-mobile');
        // navbar.classList.add('is-active');
    });

    navbar.addEventListener('click', () => {
        navbar.classList.remove('is-mobile');
        // navbar.classList.remove('is-active');
    });
});
