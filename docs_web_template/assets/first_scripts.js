let firstRun = true;

let nicerName = (s) => {
    const last_slash = s.lastIndexOf("/");
    const base = s.substring(last_slash);
    const name = base === "/README.html" ? s.substring(0, last_slash) : s.substring(0, s.length - 5);
    return name.length > 25 ? '…' + name.substring(name.length-29): name;
};

const toggleSidebar = () => {
    const sideNav = document.querySelector('.tui-sidenav');

    if (sideNav) {
        const actualBodyStyle = document.getElementById("actual-body").style;
        if (sideNav.classList.contains('active')) {
            //sideNav.classList.remove('active');
            actualBodyStyle.marginLeft = '20px';
            actualBodyStyle.maxWidth = '100%';
        } else {
            actualBodyStyle.marginLeft = '390px';
            actualBodyStyle.maxWidth = '70%';
            if (firstRun) {
                firstRun = false;
                sideNav.classList.add('active');
            }
        }
    }
}
const urls = $URLS;
