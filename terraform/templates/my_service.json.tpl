[
  {
    "name": "${container_name}",
    "image": "${container_image}",
    "cpu": ${container_cpu},
    "memory": ${container_memory},
    "networkMode": "",
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/fargate/${environment}/${application_name}",
          "awslogs-region": "${aws_region}",
          "awslogs-stream-prefix": "ecs"
        }
    },
    "portMappings": [
      {
        "containerPort": ${container_port},
        "hostPort": ${container_port}
      }
    ],
    "environment": [
    ]
  }
]