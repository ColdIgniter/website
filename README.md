# ColdIgniter Website

The website of [ColdIgniter](https://github.com/ColdIgniter/coldigniter), a CFML port of CodeIgniter 4. The site is itself a ColdIgniter application.

The user guide is not here. It has its own repository, [ColdIgniter/userguide](https://github.com/ColdIgniter/userguide), and is served at `/user_guide`.

## Folders

| Folder | What it holds |
|---|---|
| `app/` | The site: configuration, controllers and views. |
| `public/` | The only folder the web server serves. |
| `system/` | A copy of the framework. Do not change files here. |
| `writable/` | Files the site writes: cache, logs and sessions. |

The file `.coldigniter-version` says which version of ColdIgniter the copy in `system/` is.

## Update the framework

1. Open the workflow "update framework" under Actions and run it. Give it a tag such as `v4.1.0`, or `trunk`.
2. The workflow replaces `system/` and opens a pull request.
3. The pull request lists the files of the starter application (`app/`, `public/`, `env`) that changed in ColdIgniter. The site has its own copies of them, so merge those changes by hand.
4. Merge the pull request.

## Set up

1. Make `public/` the home directory of the web site.
2. Copy `env` to `.env` and set `app.baseURL`. The file `.env` is never committed.

## License

MIT
