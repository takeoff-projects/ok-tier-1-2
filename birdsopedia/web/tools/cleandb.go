package main

import (
	"cloud.google.com/go/firestore"
	"context"
	"fmt"
	"google.golang.org/api/iterator"
	"log"
	"os"
)

const collection = "bird"

func CreateDbClient() (*firestore.Client, error) {
	ctx := context.Background()

	projectID := os.Getenv("GOOGLE_CLOUD_PROJECT")
	if projectID == "" {
		log.Fatalf("Set Firebase project ID via GOOGLE_CLOUD_PROJECT env variable.")
	}

	client, err := firestore.NewClient(ctx, projectID)

	return client, err
}

func main() {
	client, err := CreateDbClient()
	if err == nil && client != nil {
		ctx := context.Background()

		if err := deleteCollection(ctx, client, client.Collection(collection), 2); err != nil {
			log.Fatalf("Cannot delete collectionL %v", err)
		}
		fmt.Printf("Firestore collection %s was cleaned \n", collection)
	} else {
		log.Fatalf("Unable to create Firestore client %v", err)
	}
}

func deleteCollection(ctx context.Context, client *firestore.Client,
	ref *firestore.CollectionRef, batchSize int) error {

	for {
		// Get a batch of documents
		iter := ref.Limit(batchSize).Documents(ctx)
		numDeleted := 0

		// Iterate through the documents, adding
		// a delete operation for each one to a
		// WriteBatch.
		batch := client.Batch()
		for {
			doc, err := iter.Next()
			if err == iterator.Done {
				break
			}
			if err != nil {
				return err
			}

			batch.Delete(doc.Ref)
			numDeleted++
		}

		// If there are no documents to delete,
		// the process is over.
		if numDeleted == 0 {
			return nil
		}

		_, err := batch.Commit(ctx)
		if err != nil {
			return err
		}
	}
}
