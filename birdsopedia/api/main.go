package main

import (
	"cloud.google.com/go/firestore"
	"encoding/json"
	"fmt"
	"github.com/google/uuid"
	"github.com/gorilla/mux"
	"io/ioutil"
	"log"
	"net/http"
	"ok.com/birdsopedia-api/birdsdb"
	"os"
	"time"
)

func (app *Application) handler(w http.ResponseWriter, r *http.Request) {
	_, err := fmt.Fprintf(w, "ok!")
	if err != nil {
		fmt.Println(err)
	}
}

func (app *Application) indexHandler(w http.ResponseWriter, r *http.Request) {
	_, err := fmt.Fprintf(w, "Welcome to the Birds API!")
	if err != nil {
		log.Println(err)
	}
}

func (app *Application) getAllHandler(w http.ResponseWriter, r *http.Request) {
	var birds = birdsdb.GetBirds(app.db)
	log.Println("Get all Birds")
	json.NewEncoder(w).Encode(birds)
}

func (app *Application) editHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id := vars["id"]

	reqBody, _ := ioutil.ReadAll(r.Body)
	var bird birdsdb.Bird
	json.Unmarshal(reqBody, &bird)
	bird.ID = id

	birdsdb.UpdateBird(app.db, bird)
	log.Printf("Bird was Updated %s", bird.ID)
	json.NewEncoder(w).Encode(bird)

}

func (app *Application) addHandler(w http.ResponseWriter, r *http.Request) {
	newID := uuid.New().String()
	fmt.Printf("Bird was Added %s \n", newID)

	reqBody, _ := ioutil.ReadAll(r.Body)
	var bird birdsdb.Bird
	json.Unmarshal(reqBody, &bird)

	bird.ID = newID
	birdsdb.AddBird(app.db, bird)

	json.NewEncoder(w).Encode(bird)
}

type DeleteResponse struct {
	ID string `json:"id"`
}

func (app *Application) deleteHandler(w http.ResponseWriter, r *http.Request) {
	var id = mux.Vars(r)["id"]
	birdsdb.DeleteBird(app.db, id)
	log.Printf("Bird deleted %s \n", id)
	json.NewEncoder(w).Encode(DeleteResponse{ID: id})
}

func (app *Application) newRouter() *mux.Router {

	router := mux.NewRouter().StrictSlash(true)

	router.HandleFunc("/ping", app.handler).Methods("GET")
	router.HandleFunc("/", app.indexHandler).Methods("GET")
	router.HandleFunc("/birds", app.getAllHandler).Methods("GET")
	router.HandleFunc("/birds", app.addHandler).Methods("POST")
	router.HandleFunc("/birds/{id}", app.editHandler).Methods("PUT")
	router.HandleFunc("/birds/{id}", app.deleteHandler).Methods("DELETE")

	router.HandleFunc("/swagger", func(res http.ResponseWriter, req *http.Request) {
		http.ServeFile(res, req, "swaggerui/swagger.json")
	})

	staticServer := http.FileServer(http.Dir("swaggerui"))
	sh := http.StripPrefix("/swaggerui/", staticServer)
	router.PathPrefix("/swaggerui/").Handler(sh)

	return router
}

type Application struct {
	db *firestore.Client
}

func createApplication() *Application {
	db, err := birdsdb.CreateDbClient()
	if err != nil {
		log.Fatalf("Unable to init DbClient %v \n", err)
	}
	appContext := &Application{db: db}
	return appContext
}

func main() {
	application := createApplication()

	fmt.Println("Starting server...")
	router := application.newRouter()

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
		log.Printf("defaulting to port %s", port)
	}

	srv := &http.Server{
		Handler:      router,
		Addr:         "0.0.0.0:" + port,
		WriteTimeout: 15 * time.Second,
		ReadTimeout:  15 * time.Second,
	}
	fmt.Printf("Serving on port %s \n", port)
	log.Fatal(srv.ListenAndServe())
}
