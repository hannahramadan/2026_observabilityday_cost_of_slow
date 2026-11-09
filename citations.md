# Citations

Sources for the talk, in the order they come up.

## How we perceive slow

- Robert B. Miller, "Response time in man-computer conversational transactions," *AFIPS Fall Joint Computer Conference*, 1968. https://dl.acm.org/doi/10.1145/1476589.1476628
- Jakob Nielsen, "Response Times: The 3 Important Limits," Nielsen Norman Group, 1993 (from *Usability Engineering*). https://www.nngroup.com/articles/response-times-3-important-limits/
- Jakob Nielsen, "The Need for Speed," Nielsen Norman Group, 1997. https://www.nngroup.com/articles/the-need-for-speed-1997/
- Jakob Nielsen, "Website Response Times," Nielsen Norman Group, 2010. https://www.nngroup.com/articles/website-response-times/
- Radware, "Mobile Web Stress: The Impact of Network Speed on Emotional Engagement and Brand Perception," 2013. https://www.radware.com/blog/applicationdelivery/mobile-web-stress-the-impact-of-network-speed-on-emotional-engagement-and-brand-perception-report/
- Tammy Everts, "Slow Pages Damage How Users Perceive Your Content, Design, and Navigation," Web Performance Calendar, 2013. https://calendar.perfplanet.com/2013/slow-pages-damage-perception/
- SpeedCurve, "The Psychology of Site Speed and User Happiness." https://www.speedcurve.com/web-performance-guide/the-psychology-of-web-performance/
- Felicia Fang-Yi Tan, Moritz A. Messerschmidt, Wen Yin, Oded Nov, "The Impact of Response Latency and Task Type on Human-LLM Interaction and Perception," *CHI '26*, 2026. https://dl.acm.org/doi/full/10.1145/3772318.3790716 (preprint: https://arxiv.org/abs/2604.06183)

## What slow costs

- Greg Linden, "Make Data Useful," Stanford CS345 lecture slides, 2006 ("Every 100ms delay costs 1% of sales"). https://web.archive.org/web/20070128145055/http://home.blarg.net/~glinden/StanfordDataMining.2006-11-28.ppt
- Greg Linden, "Marissa Mayer at Web 2.0," *Geeking with Greg*, 2006. https://glinden.blogspot.com/2006/11/marissa-mayer-at-web-20.html
- DoubleClick by Google, "The Need for Mobile Speed," 2016. https://web.archive.org/web/20180105202345/https://www.doubleclickbygoogle.com/articles/mobile-speed-matters/
- ITIC, "ITIC 2024 Hourly Cost of Downtime Part 2," 2024. https://itic-corp.com/itic-2024-hourly-cost-of-downtime-part-2/
- New Relic, *2026 Observability Forecast*, 2026. https://newrelic.com/resources/report/observability-forecast/2026

## Business observability and KPIs

- Dynatrace, "What is business observability?" https://www.dynatrace.com/knowledge-base/business-observability/
- Investopedia, "Key Performance Indicators (KPIs)." https://www.investopedia.com/terms/k/kpi.asp
- John F. Rockart, "Chief Executives Define Their Own Data Needs," *Harvard Business Review*, March 1979. https://hbr.org/1979/03/chief-executives-define-their-own-data-needs
- John F. Rockart, "A New Approach to Defining the Chief Executive's Information Needs," MIT Sloan working paper, 1978. http://hdl.handle.net/1721.1/1942
- Apdex Alliance, *Apdex Technical Specification v1.1*, 2007. https://www.apdex.org/wp-content/uploads/2020/09/ApdexTechnicalSpecificationV11_000.pdf

## Partnering with the business

- FinOps Foundation, "FinOps Principles." https://www.finops.org/framework/principles/
- Google, *The Site Reliability Workbook*, "Implementing SLOs." https://sre.google/workbook/implementing-slos/

## OpenTelemetry

- Semantic conventions overview. https://opentelemetry.io/docs/concepts/semantic-conventions/
- Sampling. https://opentelemetry.io/docs/concepts/sampling/
- Logs data model (events are log records with an event name). https://opentelemetry.io/docs/specs/otel/logs/data-model/
- GenAI semantic conventions: client inference metrics, including `gen_ai.client.inference.duration` and its recommended bucket boundaries. https://github.com/open-telemetry/semantic-conventions-genai/blob/main/docs/gen-ai/client-inference.md
- Prometheus, "Metric and label naming" (every label combination is a new time series). https://prometheus.io/docs/practices/naming/

### Cost in the semantic conventions

- `service.instance.cost_center.id` and `.name`, added in v1.45.0. https://github.com/open-telemetry/semantic-conventions/pull/3866
- Proposal: `service.business_unit.id`. https://github.com/open-telemetry/semantic-conventions/issues/3475
- Proposal: `service.owner`. https://github.com/open-telemetry/semantic-conventions/issues/3101
- Discussion: an attribute for a tenant. https://github.com/open-telemetry/semantic-conventions/issues/162
- Proposal: Cloud Financial Management conventions. https://github.com/open-telemetry/semantic-conventions/issues/1598
- Proposal: per-operation GenAI cost (`gen_ai.usage.cost.*`). https://github.com/open-telemetry/semantic-conventions-genai/pull/443
- Proposal: per-class GenAI cost breakdown. https://github.com/open-telemetry/semantic-conventions-genai/pull/607 (issue: https://github.com/open-telemetry/semantic-conventions-genai/issues/484)
- Proposal: cost allocation attributes for GenAI spend. https://github.com/open-telemetry/semantic-conventions-genai/issues/575
- Discussion: pricing provenance for GenAI cost. https://github.com/open-telemetry/semantic-conventions-genai/issues/624
