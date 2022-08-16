# Identity-Aware Proxy (IAP) Ingress

[IAP](https://cloud.google.com/iap) establishes a central authorization layer via HTTPS and enables application-level access control. Your kubeflow cluster can only be accessed through the proxy by users, who have the correct Identity and Access Management (IAM) role. When you grant a user access by IAP, they're subject to the fine-grained access controls without requiring a VPN. When a user tries to access the kubeflow cluster, IAP performs authentication and authorization checks.

IAP is [integrated through Ingress](https://cloud.google.com/iap/docs/enabling-kubernetes-howto). The incoming traffic is handled by [HTTPS Load Balancing](https://cloud.google.com/load-balancing/docs/https), a component of Cloud Load Balancing, configured by the Ingress controller. The Ingress controller gets configuration information from an [Ingress](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress) object (**envoy-ingress**) that is associated with one or more Service objects. Each Service object holds routing information that is used to direct an incoming request to a particular Pod and port. The Ingress controller reads configuration information from the BackendConfig (**iap-backendconfig**) and sets up the load balancer accordingly. **iap-backendconfig** holds configuration information that is specific to Cloud Load Balancing.

To create a fully qualified domain name (FQDN) for the kubeflow cluster and expose it through HTTPS, we employ [Cloud Endpoints](https://cloud.google.com/endpoints). Cloud Endpoints is an API management system that helps you secure, monitor, analyze, and set quotas on your APIs using the same infrastructure Google uses for its own APIs. Endpoints works with the Extensible Service Proxy (ESP) and the Extensible Service Proxy V2 (ESPv2) to provide API management. Endpoints supports version 2 of the OpenAPI Specification (formerly known as the [Swagger spec](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/2.0.md)) — the industry standard for defining REST APIs. If you are unfamiliar with the OpenAPI Specification, see [OpenAPI Overview](https://cloud.google.com/endpoints/docs/openapi/openapi-overview).

## iap-enabler

[IAP uses](https://cloud.google.com/iap/docs/signed-headers-howto) JSON Web Tokens ([JWT](https://jwt.io/introduction)) to make sure that a request to kubeflow is authorized. This protects kubeflow from IAP being accidentally disabled, misconfigured firewalls, and access from within the project. This *Deployment* applies a RequestAuthentication (**ingress-jwt**) to the kubeflow cluster based on the [policy.yaml template](./base/policy.yaml).

## backend-updater

HTTPS Load Balancing requires a [health check](https://cloud.google.com/load-balancing/docs/health-check-concepts) to determine if backend (**istio-ingressgateway**) responds to traffic. This *StatefulSet* updates the **iap-backendconfig** with the appropriate backend port and backend path for the corresponding health check.

## cloud-endpoints-enabler

This *Deployment* is introduced to replace cloud-endpoints-controller. It [establishes a cloud endpoint](https://cloud.google.com/endpoints/docs/openapi/get-started-kubernetes-engine-espv2) using OpenAPI specification. It uses [swagger_template.yaml](./base/swagger_template.yaml) to build an appropriate OpenAPI spec. This template was used in the original [cloud-endpoint-controller](https://github.com/danisla/cloud-endpoints-controller) (deprecated) in Kubeflow 1.5.1 and earlier.
