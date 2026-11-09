# What's the Dollar Cost of Slow?

Demo app from the talk *"What's the Dollar Cost of Slow?": Answering Business Questions with OpenTelemetry*
(Observability Day, KubeCon + CloudNativeCon North America 2026).

**The scenario:** an AI support assistant. On a "slow day" the AI provider takes several extra seconds,
customers give up, and some open a support ticket. The customers and the slow day are simulated; the AI
calls are real (OpenAI).

```text
Rails app (OpenTelemetry Ruby SDK)
  --OTLP-->
    OpenTelemetry Collector -->
      Prometheus, Tempo, Loki -->
        Perses
```

## Where to look

The patterns work in any language with an OpenTelemetry SDK.

| Idea | File |
|---|---|
| **Metrics:** put a histogram bucket boundary at the business threshold (5 seconds) | `config/initializers/opentelemetry.rb` |
| **Traces:** put the customer and plan on the root span | `app/controllers/asks_controller.rb` |
| **Traces:** give each step its own span | `app/services/support_assistant/` |
| **Logs:** emit an event when a customer gives up (with the tokens already paid for) | `app/state/ask_ledger.rb` |
| **Logs:** emit an event when a support ticket is opened | `app/controllers/tickets_controller.rb` |
| **Dollars:** the business numbers (all placeholders) | `config/business.yml` |
| **Dollars:** multiply counts by business numbers | `lib/tasks/dollars.rake`, `infra/perses/provisioning/` |

The OpenAI instrumentation creates the AI span and its token counts automatically, but doesn't emit
metrics yet. `lib/otel/gen_ai_metrics_span_processor.rb` fills that gap using the standard metric names.

There's no semantic convention for a customer or account yet, so the app uses its own attributes, like
`app_name.customer.id`. `app_name` stands in for your app's name: use a prefix that's specific to you.

## Run it

You'll need Ruby 3.4, Docker, and an OpenAI API key. Each simulated question is one real OpenAI call, so
use a cheap, non-reasoning model.

```sh
bundle install
cp .env.example .env                          # add your OpenAI key and model
docker compose -f infra/docker-compose.yaml up -d
bin/rails server                              # in another terminal

bin/rails "demo:normal[20]"                   # 20 questions on a normal day
bin/rails "demo:slow[20]"                     # 20 questions on a slow day
bin/rails dollars                             # print the cost of slow
```

Dashboards are at <http://localhost:8080>. To stop and delete all data:
`docker compose -f infra/docker-compose.yaml down -v`.

No OpenAI key? With the Docker stack up (and the Rails server stopped), run
`bin/rails runner script/smoke_telemetry.rb`. It sends one sample trace, metrics and both events, so you
can see the telemetry flow end to end.

`bin/rails test` runs the tests without calling OpenAI.

## Resources

<!-- TODO -->
