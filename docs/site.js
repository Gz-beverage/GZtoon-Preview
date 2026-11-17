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
  const zoomLevel = document.querySelector('#zoom-level');
  const zoomIn = document.querySelector('#zoom-in');
  const zoomOut = document.querySelector('#zoom-out');
  const tabs = Array.from(document.querySelectorAll('.turntable-tabs .tab'));

  const count = 72;
  const sets = {
    scene: 'images/turntable/scene/',
    studio: 'images/turntable/studio/',
    rim: 'images/turntable/rim/'
  };
  const cache = {};

  let activeSet = 'scene';
  let index = 0;
  let zoom = 1;
  let dragging = false;
  let startX = 0;
  let startIndex = 0;
  let autoTimer = 0;
  let resumeTimer = 0;

  range.max = String(count - 1);

  const framesFor = (name) => {
    if (!cache[name]) {
      cache[name] = Array.from({ length: count }, (_, i) => {
        const image = new Image();
        image.src = sets[name] + 'frame_' + String(i).padStart(3, '0') + '.jpg';
        return image;
      });
    }
    return cache[name];
  };

  const render = () => {
    const frames = framesFor(activeSet);
    turntableImage.src = frames[index].src;
    range.value = String(index);
    hint.textContent = Math.round((index / count) * 360) + '°';
    turntableImage.style.transform = 'scale(' + zoom.toFixed(2) + ')';
    zoomLevel.textContent = Math.round(zoom * 100) + '%';
  };

  const show = (next) => {
    index = ((next % count) + count) % count;
    render();
  };

  const setZoom = (value) => {
    zoom = Math.min(2.5, Math.max(1, value));
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
    if (dragging || zoom > 1) return;
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    autoTimer = setInterval(() => show(index + 1), 90);
  };

  const scheduleAuto = () => {
    stopAuto();
    resumeTimer = setTimeout(startAuto, 3200);
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

  frame.addEventListener('wheel', (event) => {
    event.preventDefault();
    stopAuto();
    setZoom(zoom - event.deltaY * 0.0015);
    scheduleAuto();
  }, { passive: false });

  zoomIn.addEventListener('click', () => { stopAuto(); setZoom(zoom + 0.25); scheduleAuto(); });
  zoomOut.addEventListener('click', () => { stopAuto(); setZoom(zoom - 0.25); scheduleAuto(); });

  tabs.forEach((tab) => {
    tab.addEventListener('click', () => {
      const name = tab.dataset.set;
      if (!name || name === activeSet) return;
      tabs.forEach((item) => item.classList.toggle('is-active', item === tab));
      activeSet = name;
      framesFor(name);
      stopAuto();
      render();
      scheduleAuto();
    });
  });

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
