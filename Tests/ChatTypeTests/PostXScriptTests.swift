import Foundation
import Testing

@Test
func printModeDescribesChromeUseWorkflow() throws {
    let fixture = try FakeChromeAuthFixture()
    let result = try runPostScript(
        arguments: ["--print", "ChatType update"],
        environment: fixture.environment
    )

    #expect(result.status == 0, Comment(rawValue: result.stderr))
    #expect(result.stdout.contains("chrome-use"))
    #expect(result.stdout.contains("Chrome for Testing"))
    #expect(result.stdout.contains("auth-cdp"))
    #expect(result.stdout.contains("https://x.com/compose/post"))
    #expect(!result.stdout.contains("xurl"))
}

@Test
func liveModeUsesChromeAuthWorkflowAndReturnsVerifiedPostURL() throws {
    let fixture = try FakeChromeAuthFixture()
    let postText = "ChatType v0.1.2 shipped"

    let result = try runPostScript(
        arguments: [postText],
        environment: fixture.environment
    )

    #expect(result.status == 0, Comment(rawValue: result.stderr))
    #expect(result.stdout.contains("https://x.com/longbiaochen/status/1234567890"))

    let postedText = try String(contentsOf: fixture.textFile, encoding: .utf8)
    #expect(postedText == postText)
}

private struct ScriptResult {
    let status: Int32
    let stdout: String
    let stderr: String
}

private func runPostScript(arguments: [String], environment: [String: String]) throws -> ScriptResult {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    process.arguments = ["scripts/post_x.sh"] + arguments
    process.currentDirectoryURL = URL(fileURLWithPath: "/Users/longbiao/Projects/chat-type")

    var mergedEnvironment = ProcessInfo.processInfo.environment
    for (key, value) in environment {
        mergedEnvironment[key] = value
    }
    process.environment = mergedEnvironment

    let stdout = Pipe()
    let stderr = Pipe()
    process.standardOutput = stdout
    process.standardError = stderr

    try process.run()
    process.waitUntilExit()

    return ScriptResult(
        status: process.terminationStatus,
        stdout: String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "",
        stderr: String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    )
}

private struct FakeChromeAuthFixture {
    let root: URL
    let environment: [String: String]
    let textFile: URL

    init() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let scriptsDirectory = root
            .appendingPathComponent("chrome-auth", isDirectory: true)
            .appendingPathComponent("scripts", isDirectory: true)
        try FileManager.default.createDirectory(at: scriptsDirectory, withIntermediateDirectories: true)

        let stateFile = root.appendingPathComponent("state.env")
        textFile = root.appendingPathComponent("posted.txt")

        let openURL = scriptsDirectory.appendingPathComponent("open_url.sh")
        try """
        #!/usr/bin/env bash
        set -euo pipefail
        state_file="${FAKE_CHROME_USE_STATE:?}"
        posted=0
        if [[ -f "$state_file" ]]; then
          # shellcheck disable=SC1090
          source "$state_file"
          posted="${POSTED:-0}"
        fi
        printf 'OPENED=1\\nPOSTED=%s\\n' "$posted" >"$state_file"
        echo "http://127.0.0.1:9223"
        """.write(to: openURL, atomically: true, encoding: .utf8)
        try setExecutable(openURL)

        let authCDP = scriptsDirectory.appendingPathComponent("auth-cdp")
        try """
        #!/usr/bin/env bash
        set -euo pipefail

        state_file="${FAKE_CHROME_USE_STATE:?}"
        text_file="${FAKE_CHROME_USE_TEXT:?}"
        command="${1:-}"
        if [[ -n "$command" ]]; then
          shift
        fi

        OPENED=0
        POSTED=0
        if [[ -f "$state_file" ]]; then
          # shellcheck disable=SC1090
          source "$state_file"
        fi

        get_flag() {
          local name="$1"
          shift
          while [[ "$#" -gt 0 ]]; do
            if [[ "$1" == "$name" ]]; then
              echo "${2:-}"
              return 0
            fi
            shift
          done
          return 1
        }

        write_state() {
          printf 'OPENED=%s\\nPOSTED=%s\\n' "$OPENED" "$POSTED" >"$state_file"
        }

        selector="$(get_flag --selector "$@" || true)"
        text="$(get_flag --text "$@" || true)"

        case "$command" in
          list-pages)
            if [[ "$OPENED" == "1" ]]; then
              cat <<'JSON'
        {
          "browserUrl": "http://127.0.0.1:9223",
          "pageCount": 1,
          "selectedPage": {
            "id": "page-compose",
            "title": "Post",
            "url": "https://x.com/compose/post",
            "selected": true
          },
          "pages": [
            {
              "id": "page-compose",
              "title": "Post",
              "url": "https://x.com/compose/post",
              "selected": true
            }
          ]
        }
        JSON
            else
              cat <<'JSON'
        {
          "browserUrl": "http://127.0.0.1:9223",
          "pageCount": 1,
          "selectedPage": {
            "id": "page-blank",
            "title": "about:blank",
            "url": "about:blank",
            "selected": true
          },
          "pages": [
            {
              "id": "page-blank",
              "title": "about:blank",
              "url": "about:blank",
              "selected": true
            }
          ]
        }
        JSON
            fi
            ;;
          bind-page)
            cat <<'JSON'
        {
          "browserUrl": "http://127.0.0.1:9223",
          "binding": {
            "bindingId": "binding-compose",
            "pageId": "page-compose",
            "url": "https://x.com/compose/post",
            "title": "Post",
            "createdAt": "2026-04-19T00:00:00Z"
          },
          "selectedPage": {
            "id": "page-compose",
            "title": "Post",
            "url": "https://x.com/compose/post",
            "selected": true
          },
          "pageCount": 1
        }
        JSON
            ;;
          navigate)
            cat <<'JSON'
        {
          "browserUrl": "http://127.0.0.1:9223",
          "navigatedTo": "https://x.com/compose/post",
          "selectedPage": {
            "id": "page-compose",
            "title": "Post",
            "url": "https://x.com/compose/post",
            "selected": true
          },
          "page": {
            "title": "Post",
            "url": "https://x.com/compose/post",
            "readyState": "complete"
          }
        }
        JSON
            ;;
          find)
            case "$selector" in
              "a[href='/login']")
                cat <<'JSON'
        {
          "browserUrl": "http://127.0.0.1:9223",
          "selectedPage": {
            "id": "page-compose",
            "title": "Post",
            "url": "https://x.com/compose/post",
            "selected": true
          },
          "found": false,
          "reason": "not_found",
          "selector": "a[href='/login']"
        }
        JSON
                ;;
              '[data-testid="tweetTextarea_0"]')
                cat <<'JSON'
        {
          "browserUrl": "http://127.0.0.1:9223",
          "selectedPage": {
            "id": "page-compose",
            "title": "Post",
            "url": "https://x.com/compose/post",
            "selected": true
          },
          "found": true,
          "selector": "[data-testid=\\\"tweetTextarea_0\\\"]",
          "tagName": "DIV",
          "id": "",
          "className": "composer",
          "text": "",
          "ariaLabel": "",
          "visible": true,
          "disabled": false,
          "editable": true,
          "rect": {
            "x": 0,
            "y": 0,
            "width": 640,
            "height": 160
          }
        }
        JSON
                ;;
              'button[data-testid="tweetButton"]')
                cat <<'JSON'
        {
          "browserUrl": "http://127.0.0.1:9223",
          "selectedPage": {
            "id": "page-compose",
            "title": "Post",
            "url": "https://x.com/compose/post",
            "selected": true
          },
          "found": true,
          "selector": "button[data-testid=\\\"tweetButton\\\"]",
          "tagName": "BUTTON",
          "id": "",
          "className": "post-button",
          "text": "Post",
          "ariaLabel": "",
          "visible": true,
          "disabled": false,
          "editable": false,
          "rect": {
            "x": 600,
            "y": 12,
            "width": 96,
            "height": 32
          }
        }
        JSON
                ;;
              *)
                printf '{"browserUrl":"http://127.0.0.1:9223","selectedPage":{"id":"page-compose","title":"Post","url":"https://x.com/compose/post","selected":true},"found":false,"reason":"not_found","selector":"%s"}\n' "$selector"
                ;;
            esac
            ;;
          fill)
            printf '%s' "$text" >"$text_file"
            cat <<'JSON'
        {
          "browserUrl": "http://127.0.0.1:9223",
          "selectedPage": {
            "id": "page-compose",
            "title": "Post",
            "url": "https://x.com/compose/post",
            "selected": true
          },
          "selector": "[data-testid=\\\"tweetTextarea_0\\\"]",
          "mode": "fill",
          "updated": true,
          "valueLength": 23,
          "tagName": "DIV"
        }
        JSON
            ;;
          click)
            POSTED=1
            write_state
            cat <<'JSON'
        {
          "browserUrl": "http://127.0.0.1:9223",
          "selectedPage": {
            "id": "page-compose",
            "title": "Post",
            "url": "https://x.com/compose/post",
            "selected": true
          },
          "clicked": true,
          "selector": "button[data-testid=\\\"tweetButton\\\"]",
          "tagName": "BUTTON",
          "id": "",
          "className": "post-button",
          "position": {
            "x": 610,
            "y": 20
          }
        }
        JSON
            ;;
          snapshot)
            posted_text=""
            if [[ -f "$text_file" ]]; then
              posted_text="$(cat "$text_file")"
            fi
            if [[ "$POSTED" == "1" ]]; then
              cat <<JSON
        {
          "browserUrl": "http://127.0.0.1:9223",
          "mode": "dom",
          "selectedPage": {
            "id": "page-compose",
            "title": "Posted",
            "url": "https://x.com/longbiaochen/status/1234567890",
            "selected": true
          },
          "page": {
            "title": "Posted",
            "url": "https://x.com/longbiaochen/status/1234567890",
            "readyState": "complete",
            "activeElement": null
          },
          "snapshot": {
            "interactive": [
              {
                "tagName": "A",
                "id": "",
                "className": "status-link",
                "text": "$posted_text",
                "ariaLabel": "",
                "href": "https://x.com/longbiaochen/status/1234567890",
                "rect": {
                  "x": 0,
                  "y": 0,
                  "width": 640,
                  "height": 48
                }
              }
            ],
            "bodyTextSample": "$posted_text"
          },
          "outputPath": null
        }
        JSON
            else
              cat <<'JSON'
        {
          "browserUrl": "http://127.0.0.1:9223",
          "mode": "dom",
          "selectedPage": {
            "id": "page-compose",
            "title": "Post",
            "url": "https://x.com/compose/post",
            "selected": true
          },
          "page": {
            "title": "Post",
            "url": "https://x.com/compose/post",
            "readyState": "complete",
            "activeElement": null
          },
          "snapshot": {
            "interactive": [],
            "bodyTextSample": ""
          },
          "outputPath": null
        }
        JSON
            fi
            ;;
          *)
            echo "unsupported fake auth-cdp command: $command" >&2
            exit 1
            ;;
        esac
        """.write(to: authCDP, atomically: true, encoding: .utf8)
        try setExecutable(authCDP)

        environment = [
            "CHROME_AUTH_SKILL_DIR": root.appendingPathComponent("chrome-auth").path,
            "FAKE_CHROME_USE_STATE": stateFile.path,
            "FAKE_CHROME_USE_TEXT": textFile.path,
        ]
    }
}

private func setExecutable(_ url: URL) throws {
    try FileManager.default.setAttributes(
        [.posixPermissions: 0o755],
        ofItemAtPath: url.path
    )
}
