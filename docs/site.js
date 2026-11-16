const button = document.querySelector('#copy-url');
const status = document.querySelector('#copy-status');
button.addEventListener('click', async () => {
  const text = document.querySelector('#git-url').textContent;
  try {
    await navigator.clipboard.writeText(text);
    button.textContent = '已复制';
    status.textContent = '在 Unity Package Manager 中粘贴即可安装。';
  } catch {
    const selection = window.getSelection();
    const range = document.createRange();
    range.selectNodeContents(document.querySelector('#git-url'));
    selection.removeAllRanges();
    selection.addRange(range);
    status.textContent = '地址已选中，请复制后粘贴到 Unity Package Manager。';
  }
});
