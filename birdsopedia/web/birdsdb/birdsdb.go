package birdsdb

import (
	"context"
	"errors"
	"fmt"
	"github.com/google/uuid"
	"google.golang.org/api/iterator"
	"log"
	"os"

	"cloud.google.com/go/firestore"
)

const collection = "bird"

// Birds model
type Bird struct {
	ID          string `firestore:"id,omitempty"`
	Species     string `firestore:"species,omitempty"`
	Description string `firestore:"description,omitempty"`
}

func GetBirds(client *firestore.Client) []Bird {
	ctx := context.Background()
	iter := client.Collection(collection).Documents(ctx)
	birds := make([]Bird, 0, 10)
	for {
		doc, err := iter.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			log.Fatalf("Unable to query birds %v \n", err)
		}
		var b Bird
		conversionError := doc.DataTo(&b)
		if conversionError == nil {
			birds = append(birds, b)
		} else {
			log.Fatalf("Unable to convert into Bird: %v \n", err)
		}
	}
	return birds
}

func CreateDbClient() (*firestore.Client, error) {
	ctx := context.Background()

	projectID := os.Getenv("GOOGLE_CLOUD_PROJECT")
	if projectID == "" {
		log.Fatalf("Set Firebase project ID via GOOGLE_CLOUD_PROJECT env variable.")
	}

	client, err := firestore.NewClient(ctx, projectID)

	return client, err
}

func GetBirdbyID(client *firestore.Client, key string) (Bird, error) {
	for _, bird := range GetBirds(client) {
		if bird.ID == key {
			return bird, nil
		}
	}
	return Bird{}, errors.New("not found")
}

func AddBird(client *firestore.Client, bird Bird) {
	newID := uuid.New().String()
	bird.ID = newID
	ctx := context.Background()

	_, err := client.Collection(collection).Doc(newID).Set(ctx, bird)
	if err != nil {
		log.Printf("An error has occurred: %s", err)
	}
}

func UpdateBird(client *firestore.Client, updatedBird Bird) {
	ctx := context.Background()
	for _, bird := range GetBirds(client) {
		if bird.ID == updatedBird.ID {
			_, err := client.Collection(collection).Doc(updatedBird.ID).Set(ctx, updatedBird)
			if err != nil {
				fmt.Printf("Bird was not updated: %v \n", err)
			}
			fmt.Printf("Bird was updated: %v \n", updatedBird)
		}
	}
}

func DeleteBird(client *firestore.Client, id string) {
	ctx := context.Background()
	for _, bird := range GetBirds(client) {
		if bird.ID == id {
			_, err := client.Collection(collection).Doc(id).Delete(ctx)
			if err != nil {
				fmt.Printf("Bird was not deleted: %v \n", err)
			}
			fmt.Printf("Bird %s was deleted! \n", id)
		}
	}
}
