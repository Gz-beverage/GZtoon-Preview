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

const turntableImage = document.querySelector('#turntable-image');
if (turntableImage) {
  const frame = document.querySelector('#turntable-frame');
  const range = document.querySelector('#turntable-range');
  const hint = document.querySelector('#turntable-hint');
  const count = 72;
  const prefix = 'images/turntable/frame_';
  const frames = Array.from({ length: count }, (_, i) => {
    const image = new Image();
    image.src = prefix + String(i).padStart(3, '0') + '.jpg';
    return image;
  });

  let index = 0;
  let dragging = false;
  let startX = 0;
  let startIndex = 0;
  let autoTimer = 0;
  let resumeTimer = 0;

  range.max = String(count - 1);

  const render = () => {
    turntableImage.src = frames[index].src;
    range.value = String(index);
    hint.textContent = Math.round((index / count) * 360) + '°';
  };

  const show = (next) => {
    index = ((next % count) + count) % count;
    render();
  };

  const stopAuto = () => {
    clearInterval(autoTimer);
    autoTimer = 0;
    clearTimeout(resumeTimer);
    resumeTimer = 0;
  };

  const startAuto = () => {
    if (autoTimer) return;
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    autoTimer = setInterval(() => show(index + 1), 90);
  };

  const scheduleAuto = () => {
    stopAuto();
    resumeTimer = setTimeout(startAuto, 2600);
  };

  range.addEventListener('input', () => {
    stopAuto();
    show(Number(range.value));
    scheduleAuto();
  });

  frame.addEventListener('pointerdown', (event) => {
    dragging = true;
    startX = event.clientX;
    startIndex = index;
    frame.classList.add('dragging');
    frame.setPointerCapture(event.pointerId);
    stopAuto();
  });

  frame.addEventListener('pointermove', (event) => {
    if (!dragging) return;
    show(startIndex + Math.round((event.clientX - startX) / 12));
  });

  const release = (event) => {
    if (!dragging) return;
    dragging = false;
    frame.classList.remove('dragging');
    if (frame.hasPointerCapture(event.pointerId)) frame.releasePointerCapture(event.pointerId);
    scheduleAuto();
  };

  frame.addEventListener('pointerup', release);
  frame.addEventListener('pointercancel', release);

  render();

  if ('IntersectionObserver' in window) {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) startAuto();
        else stopAuto();
      });
    }, { threshold: 0.35 });
    observer.observe(frame);
  } else {
    startAuto();
  }
}
