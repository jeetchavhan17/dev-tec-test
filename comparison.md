# ECS EC2 vs ECS Fargate — quick comparison

## ECS EC2 (what we implemented)
- Pros:
  - Lower cost at scale for steady workloads (you manage EC2 instances).
  - Full control over instance type, kernel, additional host-level software.
  - Easy to run daemons or sidecars on host.
- Cons:
  - Operational overhead: patching, AMI updates, capacity planning.
  - Need to manage autoscaling groups and instance profiles.
  - VM-level attack surface.

## ECS Fargate
- Pros:
  - Serverless: no EC2 management, faster to deploy user space workloads.
  - Simpler scaling for many microservices and bursty workloads.
  - Pricing is based on vCPU and memory per task — often simpler.
- Cons:
  - Higher per-task cost for very large, steady workloads.
  - Less control over the underlying host (can't run privileged workloads).
  - Some features (host access) not available.

## Recommendation
- Use Fargate for small teams and microservice-first deployments where ops overhead must be minimal.
- Use ECS EC2 when you need custom host-level tooling, lower cost at large scale, or special hardware/daemon workloads.
