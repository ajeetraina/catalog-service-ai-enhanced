#!/bin/bash

# Wait for Kafka to be ready
sleep 10

# Create topics
docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --create \
  --topic vendor-evaluations \
  --bootstrap-server localhost:9092 \
  --partitions 3 \
  --replication-factor 1

docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --create \
  --topic product-catalog \
  --bootstrap-server localhost:9092 \
  --partitions 3 \
  --replication-factor 1

docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --create \
  --topic market-research \
  --bootstrap-server localhost:9092 \
  --partitions 3 \
  --replication-factor 1

docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --create \
  --topic agent-events \
  --bootstrap-server localhost:9092 \
  --partitions 3 \
  --replication-factor 1

docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --create \
  --topic customer-preferences \
  --bootstrap-server localhost:9092 \
  --partitions 3 \
  --replication-factor 1

echo "Kafka topics created successfully!"
