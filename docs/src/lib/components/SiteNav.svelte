<script lang="ts">
  import { base } from "$app/paths";
</script>

<header class="site-nav-header">
  <nav class="site-nav">
    <a href="{base}/" class="site-nav-logo">consult-user-mcp</a>
    <div class="site-nav-groups">
      <div class="site-nav-group">
        <div class="site-nav-links">
          <a href="{base}/" class="site-nav-link">Home</a>
          <a href="{base}/#install" class="site-nav-link">Install</a>
          <a href="{base}/demo" class="site-nav-link">Gallery</a>
          <a href="{base}/comparison" class="site-nav-link">Comparison</a>
          <a href="{base}/questions" class="site-nav-link">Questions</a>
          <a href="{base}/changelog" class="site-nav-link">Changelog</a>
          <a href="{base}/ecosystem" class="site-nav-link">Ecosystem</a>
        </div>
      </div>
      <div class="site-nav-group">
        <div class="site-nav-links">
          <a
            href="https://github.com/doublej/consult-user-mcp"
            class="site-nav-link site-nav-link-external"
            target="_blank"
            rel="noopener"
          >
            <span>GitHub</span>
            <span class="external-icon" aria-hidden="true">&#x2197;</span>
          </a>
        </div>
      </div>
    </div>
  </nav>
</header>

<style>
  .site-nav-header {
    padding: 20px 56px 24px;
    margin-bottom: 24px;
  }

  .site-nav {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 20px;
  }

  .site-nav-logo {
    text-decoration: none;
    color: #1a1a1a;
    font-weight: 600;
    font-size: 0.95rem;
    padding-top: 2px;
    flex-shrink: 0;
  }

  .site-nav-groups {
    display: flex;
    gap: 20px;
    flex-wrap: wrap;
    justify-content: flex-end;
  }

  .site-nav-group {
    display: flex;
    align-items: center;
    gap: 0;
  }

  .site-nav-links {
    display: flex;
    align-items: center;
    gap: 14px;
    flex-wrap: wrap;
  }

  .site-nav-link {
    color: #707070;
    text-decoration: none;
    font-size: 0.9rem;
    font-weight: 500;
  }

  .site-nav-link:hover {
    color: #1a1a1a;
  }

  .site-nav-link-external {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    color: #4f5b7c;
    border-bottom: 1px dashed #b9c2d8;
    padding-bottom: 1px;
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
      padding: 20px 32px 24px;
    }

    .site-nav {
      flex-direction: column;
      align-items: flex-start;
    }

    .site-nav-groups {
      justify-content: flex-start;
      gap: 12px;
    }

    .site-nav-group {
      align-items: center;
    }
  }

  @media (max-width: 700px) {
    .site-nav-header {
      padding: 20px 20px 22px;
    }
  }
</style>
