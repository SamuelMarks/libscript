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

document.addEventListener('DOMContentLoaded', () => {
// Define the current page
    const currentPage = window.location.pathname;

// Build the tree data
    const treeData = buildTreeJsData(urls, currentPage);

// Initialize the tree
    const tree = new Tree('#tree-container', {
        data: treeData,
        onChange: () => {
            if (tree.selectedNodes.length > 0) {
                const last = tree.selectedNodes[tree.selectedNodes.length - 1];
                if (last.class === "file-node"
                    && last.opened === true
                    && last.text.endsWith(".html")) {
                    tree.selectedNodes.length = 0;
                    tree.disabledNodes.length = 0;
                    window.location.assign(last.id);
                }
            }
        }
    });

// Function to build tree data for Treejs
    function buildTreeJsData(paths, currentPage) {
        const root = [];

        paths.forEach((path) => {
            const parts = path.split('/').filter(Boolean);
            let currentLevel = root;
            let fullPath = '';

            parts.forEach((part, index) => {
                fullPath += '/' + part;
                let existingNode = currentLevel.find(node => node.text === part);

                if (!existingNode) {
                    const isFile = index === parts.length - 1 && part.includes('.');
                    existingNode = {
                        id: fullPath,
                        text: part,
                        children: [],
                        opened: false, // Nodes are collapsed by default
                        class: isFile ? 'file-node' : 'folder-node', // Add classes for icons
                    };
                    currentLevel.push(existingNode);
                }

                // Expand nodes along the current page path
                if (currentPage.startsWith(fullPath)) {
                    existingNode.opened = true;
                }

                // Highlight the current page node
                if (fullPath === currentPage) {
                    existingNode.class += ' current-page-node'; // Append the class
                }

                currentLevel = existingNode.children;
            });
        });

        return root;
    }
});
