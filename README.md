# Gyde's Beta Tester Syncer

Automatically synchronize beta testers for your application.

This takes users in campaign monitor (but ultimately, any API Source), and then syncs them to given targets. In Gyde's case,
this means:

1. A **tester** signs up to our Beta Test mailing list with [Campaign Monitor](https://www.campaignmonitor.com/).
2. We invite them to Test Flight builds for the application as an external tester.
3. We invite them to a community slack organisation for discussion between us and Beta testers.
4. Check in to a health check url (e.g. https://healthchecks.io) if needed.
5. Party Time!

## Configuration

We use TOML (Hey, I needed an excuse to play with it) located in a `config.toml` file. As an example, this may look like:

```toml
checkin_url = "optional-check-in-url"

[sources.campaign_monitor]
list_id = "api-oriented-list-id"
api_key = "cm-api-hey-here"

[destinations.test_flight]
app_id = "your-app-id"
email = "itunes-connect-email"
password = "itunes-connect-password"

[destinations.slack]
enabled = true
token = "slack-channel-post-token"
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
