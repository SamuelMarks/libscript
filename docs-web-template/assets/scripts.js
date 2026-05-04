const currentPage = window.location.pathname;

const copyURI = (evt) => {
    evt.preventDefault();
    navigator.clipboard.writeText("https://github.com/SamuelMarks/libscript").then(() =>
            Toastify({
                text: "Copied GitHub link to clipboard",
                className: "info",
                offset: {
                    y: 12
                },
                style: {
                    background: "#0000a8",
                }
            }).showToast(),
        () => console.error('clipboard write failed')
    );
}

const TODO = () => {
    Toastify({
        text: "TODO",
        className: "info",
        offset: {
            y: 12
        },
        style: {
            background: "#0000a8",
        }
    }).showToast()
}

const twoClickDeploy = (submitButton) => {
    /*
    console.info('submitButton.id:', submitButton.id, ';');
    console.info('submitButton:', submitButton, ';');
    */
    // const twoClickForm = document.getElementById("twoClickForm");
    const cname = document.getElementById("cname");
    const log_server = document.getElementById("log_server");
    const backup_url = document.getElementById("backup_url");
    const json = document.getElementById("json");
    console.info("cname.value:", cname.value, ';');
    console.info("log_server.value:", log_server.value, ';');
    console.info("backup_url.value:", backup_url.value, ';');
    console.info("json.value:", json.value, ';');
}

function buildTree(urls) {
    const root = {};

    urls.forEach(url => {
        const parts = url.split('/').filter(part => part !== '');
        let currentNode = root;

        for (let i = 0; i < parts.length; i++) {
            const part = parts[i];
            if (!currentNode[part]) {
                currentNode[part] = {
                    __meta: {
                        isFile: i === parts.length - 1 && part.includes('.'),
                        fullPath: '/' + parts.slice(0, i + 1).join('/')
                    },
                    children: {}
                };
            }
            currentNode = currentNode[part].children;
        }
    });

    return root;
}

function renderTree(node, currentPage) {
    const ul = document.createElement('ul');

    for (const key in node) {
        if (node.hasOwnProperty(key)) {
            const item = node[key];
            const li = document.createElement('li');
            const isFile = item.__meta.isFile;
            const fullPath = item.__meta.fullPath;
            const shouldExpand = currentPage.startsWith(fullPath);

            if (isFile) {
                const a = document.createElement('a');
                a.href = fullPath;
                a.textContent = key;
                if (fullPath === currentPage) {
                    li.classList.add('current-page');
                }
                li.classList.add('file');
                li.appendChild(a);
            } else {
                li.classList.add('folder');
                if (shouldExpand) {
                    li.classList.add('expanded');
                }
                const span = document.createElement('span');
                span.textContent = key;
                span.classList.add('folder-name');

                const childrenContainer = renderTree(item.children, currentPage);

                if (!shouldExpand) {
                    childrenContainer.classList.add('hidden');
                }

                span.addEventListener('click', function (e) {
                    e.stopPropagation();
                    li.classList.toggle('expanded');
                    if (li.classList.contains('expanded')) {
                        childrenContainer.classList.remove('hidden');
                    } else {
                        childrenContainer.classList.add('hidden');
                    }
                });

                li.appendChild(span);
                li.appendChild(childrenContainer);
            }
            ul.appendChild(li);
        }
    }
    return ul;
}

document.addEventListener('DOMContentLoaded', () => {
    const treeData = buildTree(urls);

    const treeContainer = document.getElementById('tree-container');
    const tree = renderTree(treeData, currentPage);
    treeContainer.appendChild(tree);
});
