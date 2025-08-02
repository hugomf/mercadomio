#!/bin/bash

# MongoDB connection details
MONGO_URI="mongodb://192.168.1.210:27017"
DB_NAME="mercadomio"
COLLECTION="categories"

# Categories to insert
CATEGORIES=(
  "cuidados-diarios-manos-pies"
  "perfumeria-para-todos"
  "maquillaje-corrector"
  "rostro-protector-solar"
  "cuidados-diarios-hidratante-corporal"
  "finalizado"
  "rostro-contorno-de-ojos"
  "maquillaje-primer-facia"
)

# MongoDB insertion command
for CATEGORY in "${CATEGORIES[@]}"; do
  mongosh "$MONGO_URI" --eval "
    db = db.getSiblingDB('$DB_NAME');
    db.$COLLECTION.insertOne({
      slug: '$CATEGORY',
      name: '$CATEGORY',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date()
    });
  "
  if [ $? -ne 0 ]; then
    echo "Error inserting category: $CATEGORY"
    exit 1
  fi
  echo "Inserted category: $CATEGORY"
done

echo "All categories inserted successfully"