<script lang="ts">
  import { onMount } from "svelte";
  import { Application, Container, Graphics, Sprite } from "pixi.js";
  import type { Texture } from "pixi.js";

  const ACCENT = 0x5a8cff;
  const FULL_COUNT = 60;
  const SMALL_COUNT = 30;
  const BREAKPOINT = 700;
  const TRAIL_LENGTH = 5;
  const TRAIL_DECAY = 0.55;

  interface Particle {
    sprite: Sprite;
    trail: Sprite[];
    cx1: number;
    cy1: number;
    cx2: number;
    cy2: number;
    sx: number;
    sy: number;
    ex: number;
    ey: number;
    t: number;
    speed: number;
    baseAlpha: number;
    size: number;
  }

  let wrapper: HTMLDivElement;

  onMount(() => {
    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    const app = new Application();
    let particles: Particle[] = [];
    let container: Container;
    let dotTexture: Texture;
    let mounted = true;

    async function init() {
      await app.init({
        backgroundAlpha: 0,
        resizeTo: wrapper,
        antialias: true,
        autoDensity: true,
        resolution: Math.min(window.devicePixelRatio, 2),
      });

      wrapper.appendChild(app.canvas);
      app.canvas.style.position = "absolute";
      app.canvas.style.inset = "0";
      app.canvas.style.pointerEvents = "none";

      app.stage.alpha = 0.6;

      // Shared circle texture
      const g = new Graphics();
      g.circle(0, 0, 2);
      g.fill({ color: 0xffffff });
      dotTexture = app.renderer.generateTexture(g);
      g.destroy();

      // Particle container
      container = new Container();
      container.isRenderGroup = true;
      app.stage.addChild(container);

      rebuild();

      if (reducedMotion) {
        positionAll();
      } else {
        app.ticker.add(tick);
      }
    }

    function getNodes(w: number, h: number) {
      const compact = w <= BREAKPOINT;
      return {
        lx: compact ? w * 0.3 : w * 0.2,
        ly: compact ? h * 0.3 : h * 0.5,
        rx: compact ? w * 0.7 : w * 0.8,
        ry: compact ? h * 0.7 : h * 0.5,
      };
    }

    function makeArc(lx: number, ly: number, rx: number, ry: number) {
      const angle = (Math.random() * 120 - 60) * (Math.PI / 180);
      const dx = rx - lx;
      const dy = ry - ly;
      const dist = Math.sqrt(dx * dx + dy * dy);
      const spread = Math.sin(angle) * dist * 0.5;
      const nx = -dy / dist;
      const ny = dx / dist;
      const forward = Math.random() > 0.5;
      const sx = forward ? lx : rx;
      const sy = forward ? ly : ry;
      const ex = forward ? rx : lx;
      const ey = forward ? ry : ly;
      return {
        sx, sy, ex, ey,
        cx1: (sx + ex) * 0.33 + nx * spread,
        cy1: (sy + ey) * 0.33 + ny * spread,
        cx2: (sx + ex) * 0.66 + nx * spread * 0.8,
        cy2: (sy + ey) * 0.66 + ny * spread * 0.8,
      };
    }

    function createParticle(lx: number, ly: number, rx: number, ry: number): Particle {
      const size = 0.5 + Math.random() * 0.5;

      // Trail ghosts (added first so they render behind)
      const trail: Sprite[] = [];
      for (let i = 0; i < TRAIL_LENGTH; i++) {
        const ghost = new Sprite(dotTexture);
        ghost.anchor.set(0.5);
        ghost.tint = ACCENT;
        ghost.visible = false;
        container.addChild(ghost);
        trail.push(ghost);
      }

      // Main sprite
      const sprite = new Sprite(dotTexture);
      sprite.anchor.set(0.5);
      sprite.tint = ACCENT;
      sprite.scale.set(size);
      container.addChild(sprite);

      return {
        ...makeArc(lx, ly, rx, ry),
        sprite,
        trail,
        t: Math.random(),
        speed: 0.001 + Math.random() * 0.002,
        baseAlpha: 0.15 + Math.random() * 0.25,
        size,
      };
    }

    function destroyParticle(p: Particle) {
      p.sprite.destroy();
      for (const ghost of p.trail) ghost.destroy();
    }

    function rebuild() {
      if (!mounted) return;
      const w = app.screen.width;
      const h = app.screen.height;
      const count = w <= BREAKPOINT ? SMALL_COUNT : FULL_COUNT;
      const { lx, ly, rx, ry } = getNodes(w, h);

      while (particles.length > count) destroyParticle(particles.pop()!);
      while (particles.length < count) particles.push(createParticle(lx, ly, rx, ry));

      for (const p of particles) {
        Object.assign(p, makeArc(lx, ly, rx, ry));
        p.t = Math.random();
        // Hide trail ghosts on rebuild (they'll fill in naturally)
        for (const ghost of p.trail) ghost.visible = false;
      }
    }

    function bez(t: number, s: number, c1: number, c2: number, e: number) {
      const u = 1 - t;
      return u * u * u * s + 3 * u * u * t * c1 + 3 * u * t * t * c2 + t * t * t * e;
    }

    function tick() {
      for (const p of particles) {
        // Shift trail: move each ghost to the position of the one ahead
        for (let i = TRAIL_LENGTH - 1; i > 0; i--) {
          const prev = p.trail[i - 1];
          const curr = p.trail[i];
          curr.x = prev.x;
          curr.y = prev.y;
          curr.visible = prev.visible;
        }
        // Newest ghost takes current main sprite position
        p.trail[0].x = p.sprite.x;
        p.trail[0].y = p.sprite.y;
        p.trail[0].visible = true;

        // Advance particle
        p.t += p.speed;
        if (p.t >= 1) {
          p.t = 0;
          const w = app.screen.width;
          const h = app.screen.height;
          const { lx, ly, rx, ry } = getNodes(w, h);
          Object.assign(p, makeArc(lx, ly, rx, ry));
          for (const ghost of p.trail) ghost.visible = false;
        }

        p.sprite.x = bez(p.t, p.sx, p.cx1, p.cx2, p.ex);
        p.sprite.y = bez(p.t, p.sy, p.cy1, p.cy2, p.ey);

        const edgeFade = Math.min(p.t * 5, (1 - p.t) * 5, 1);
        p.sprite.alpha = p.baseAlpha * edgeFade;

        // Update trail alpha and scale
        let alpha = p.baseAlpha * edgeFade * TRAIL_DECAY;
        for (let i = 0; i < TRAIL_LENGTH; i++) {
          const ghost = p.trail[i];
          if (!ghost.visible) break;
          ghost.alpha = alpha;
          ghost.scale.set(p.size * (1 - (i + 1) * 0.08));
          alpha *= TRAIL_DECAY;
        }
      }
    }

    function positionAll() {
      for (const p of particles) {
        p.sprite.x = bez(p.t, p.sx, p.cx1, p.cx2, p.ex);
        p.sprite.y = bez(p.t, p.sy, p.cy1, p.cy2, p.ey);
        const edgeFade = Math.min(p.t * 5, (1 - p.t) * 5, 1);
        p.sprite.alpha = p.baseAlpha * edgeFade;
      }
    }

    const ro = new ResizeObserver(() => rebuild());
    ro.observe(wrapper);

    init();

    return () => {
      mounted = false;
      ro.disconnect();
      app.destroy(true, { children: true, texture: true });
    };
  });
</script>

<div bind:this={wrapper} class="field-canvas"></div>

<style>
  .field-canvas {
    position: absolute;
    inset: 0;
    overflow: hidden;
    pointer-events: none;
    border-radius: inherit;
  }
</style>
