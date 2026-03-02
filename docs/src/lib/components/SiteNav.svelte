<script lang="ts">
  import { base } from "$app/paths";
</script>

<header class="site-nav-header">
  <nav class="site-nav">
    <a href="{base}/" class="site-nav-logo">consult-user-mcp</a>
    <div class="site-nav-links site-nav-links-primary">
      <a href="{base}/" class="site-nav-link">Home</a>
      <a href="{base}/#install" class="site-nav-link">Install</a>
      <a href="{base}/demo" class="site-nav-link">Gallery</a>
      <a href="{base}/comparison" class="site-nav-link">Comparison</a>
      <a href="{base}/questions" class="site-nav-link">Questions</a>
      <a href="{base}/changelog" class="site-nav-link">Changelog</a>
    </div>
    <a
      href="https://github.com/doublej/consult-user-mcp"
      class="site-nav-link site-nav-link-external"
      target="_blank"
      rel="noopener"
    >
      <span>GitHub</span>
      <span class="external-icon" aria-hidden="true">&#x2197;</span>
    </a>
  </nav>
</header>

<style>
  .site-nav-header {
    padding: 40px 56px 34px;
    margin-bottom: 16px;
  }

  .site-nav {
    display: grid;
    grid-template-columns: max-content 1fr max-content;
    align-items: center;
    column-gap: 32px;
    row-gap: 16px;
  }

  .site-nav-logo {
    text-decoration: none;
    color: #1a1a1a;
    font-weight: 600;
    font-size: 0.95rem;
    line-height: 1;
    flex-shrink: 0;
  }

  .site-nav-links {
    display: flex;
    align-items: center;
    gap: 20px;
    flex-wrap: wrap;
    min-width: 0;
  }

  .site-nav-links-primary {
    justify-content: center;
  }

  .site-nav-link {
    color: #707070;
    text-decoration: none;
    font-size: 0.9rem;
    font-weight: 500;
    line-height: 1;
    white-space: nowrap;
  }

  .site-nav-link:hover {
    color: #1a1a1a;
  }

  .site-nav-link-external {
    display: inline-flex;
    align-items: baseline;
    gap: 5px;
    color: #4f5b7c;
    border-bottom: 1px dashed #b9c2d8;
    justify-self: end;
  }

  .site-nav-link-external:hover {
    color: #25304b;
    border-bottom-color: #8e99b5;
  }

  .external-icon {
    font-size: 0.75rem;
    line-height: 1;
    transform: translateY(-1px);
    opacity: 0.85;
  }

  @media (max-width: 900px) {
    .site-nav-header {
      padding: 24px 32px 30px;
    }

    .site-nav {
      grid-template-columns: 1fr;
      justify-items: start;
    }

    .site-nav-links-primary {
      justify-content: flex-start;
      gap: 14px 18px;
    }

    .site-nav-link-external {
      justify-self: start;
    }
  }

  @media (max-width: 700px) {
    .site-nav-header {
      padding: 22px 20px 26px;
    }
  }
</style>
