package main

import (
	"bytes"
	"cloud.google.com/go/firestore"
	"fmt"
	"github.com/gorilla/mux"
	"html/template"
	"log"
	"net/http"
	"ok.com/birdsopedia/birdsdb"
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

	var birds = birdsdb.GetBirds(app.db)

	data := HomePageData{
		PageTitle: "Home Page",
		Birds:     birds,
		Count:     len(birds),
	}

	var tpl = template.Must(template.ParseFiles("templates/index.html", "templates/layout.html"))

	buf := &bytes.Buffer{}
	err := tpl.Execute(buf, data)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		log.Println(err.Error())
		return
	}

	_, _ = buf.WriteTo(w)
	log.Println("Home Page Served")
}

func (app *Application) aboutHandler(w http.ResponseWriter, r *http.Request) {
	data := AboutPageData{
		PageTitle: "About Go Website",
	}

	var tpl = template.Must(template.ParseFiles("templates/about.html", "templates/layout.html"))

	buf := &bytes.Buffer{}
	err := tpl.Execute(buf, data)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		log.Println(err.Error())
		return
	}

	buf.WriteTo(w)
	log.Println("About Page Served")
}

func (app *Application) editHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodGet {
		log.Println("Edit Handler")
		bird, error := birdsdb.GetBirdbyID(app.db, mux.Vars(r)["id"])
		if error != nil {
			http.Error(w, error.Error(), http.StatusInternalServerError)
			log.Println(error.Error())
			return
		}

		data := EditPageData{
			PageTitle: "Edit Birds",
			Bird:      bird,
		}

		var tpl = template.Must(template.ParseFiles("templates/edit.html", "templates/layout.html"))

		buf := &bytes.Buffer{}
		err := tpl.Execute(buf, data)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			log.Println(err.Error())
			return
		}
		buf.WriteTo(w)

		log.Println("Edit Page Served")
	} else {
		// Add Event Here
		bird := birdsdb.Bird{
			ID:          r.FormValue("id"),
			Species:     r.FormValue("species"),
			Description: r.FormValue("description"),
		}
		birdsdb.UpdateBird(app.db, bird)
		log.Println("Event Updated")

		// Go back to home page
		http.Redirect(w, r, "/", http.StatusFound)
	}
}

func (app *Application) addHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodGet {
		data := AddPageData{
			PageTitle: "Add Bird",
		}

		var tpl = template.Must(template.ParseFiles("templates/add.html", "templates/layout.html"))

		buf := &bytes.Buffer{}
		err := tpl.Execute(buf, data)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			log.Println(err.Error())
			return
		}
		buf.WriteTo(w)

		log.Println("Add Page Served")
	} else {
		// Add Event Here
		bird := birdsdb.Bird{
			Species:     r.FormValue("species"),
			Description: r.FormValue("description"),
		}
		birdsdb.AddBird(app.db, bird)

		// Go back to home page
		http.Redirect(w, r, "/", http.StatusFound)
	}
}

func (app *Application) deleteHandler(w http.ResponseWriter, r *http.Request) {
	birdsdb.DeleteBird(app.db, mux.Vars(r)["id"])
	log.Println("Bird deleted")

	// Go back to home page
	http.Redirect(w, r, "/", http.StatusFound)
}

func (app *Application) newRouter() *mux.Router {

	router := mux.NewRouter().StrictSlash(true)

	router.HandleFunc("/ping", app.handler)
	router.HandleFunc("/", app.indexHandler)
	router.HandleFunc("/about", app.aboutHandler)
	router.HandleFunc("/add", app.addHandler)
	router.HandleFunc("/edit/{id}", app.editHandler)
	router.HandleFunc("/delete/{id}", app.deleteHandler)

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

// HomePageData for Index template
type HomePageData struct {
	PageTitle string
	Birds     []birdsdb.Bird
	Count     int
}

type AboutPageData struct {
	PageTitle string
}

type AddPageData struct {
	PageTitle string
}

type EditPageData struct {
	PageTitle string
	Bird      birdsdb.Bird
}
