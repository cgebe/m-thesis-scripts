package main

import (
	"archive/zip"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/gocolly/colly"
)

func main() {
	court := "bverwg"
	decisionCount := 100
	c := colly.NewCollector()

	// Find and visit all links
	c.OnHTML("a[href]", func(e *colly.HTMLElement) {
		params := strings.Split(e.Attr("href"), "&")
		if strings.HasPrefix(e.Attr("href"), "page/bsjrsprod.psml?doc.hl=1") || strings.HasSuffix(params[0], "doc.hl=1") {
			docid := strings.Split(params[1], "=")
			if docid[0] == "doc.id" && (params[6] == "doc.part=L" || params[6] == "doc.part=V") {
				downloadFileAndExtract(docid[1], court)
			} else if params[6] == "doc.part=K" {
				// skip double docs
			} else {
				panic(e.Attr("href"))
			}
		}
	})

	position := 1
	var url string
	for position <= decisionCount {
		url = "http://www.rechtsprechung-im-internet.de/jportal/portal/t/tjr/page/bsjrsprod.psml/js_peid/Suchportlet1?action=portlets.jw.MainAction&eventSubmit_doNavigate=searchInSubtree&p1=" + court + "&sortmethod=date&currentNavigationPosition=" + strconv.Itoa(position)
		c.Visit(url)
		position += 25
	}
	time.Sleep(time.Second * 5)
}

func downloadFileAndExtract(id string, dest string) {
	fmt.Printf("Downloading and extracting document %s from court %s \n", id, dest)
	url := "http://www.rechtsprechung-im-internet.de/jportal/docs/bsjrs/" + id + ".zip"
	fileName := id + ".zip"
	output, err := os.Create(fileName)
	if err != nil {
		panic(fmt.Sprintf("Error while creating", fileName, "-", err))
	}
	defer output.Close()

	response, err := http.Get(url)
	if err != nil {
		panic(fmt.Sprintf("Error while downloading", url, "-", err))
	}
	defer response.Body.Close()

	_, err = io.Copy(output, response.Body)
	if err != nil {
		panic(fmt.Sprintf("Error while writing", url, "-", err))
	}

	Unzip(fileName, dest)
	os.Remove(fileName)
}
func Unzip(src, dest string) error {
	r, err := zip.OpenReader(src)
	if err != nil {
		return err
	}
	defer func() {
		if err := r.Close(); err != nil {
			panic(err)
		}
	}()

	os.MkdirAll(dest, 0755)

	// Closure to address file descriptors issue with all the deferred .Close() methods
	extractAndWriteFile := func(f *zip.File) error {
		rc, err := f.Open()
		if err != nil {
			return err
		}
		defer func() {
			if err := rc.Close(); err != nil {
				panic(err)
			}
		}()

		path := filepath.Join(dest, f.Name)

		if f.FileInfo().IsDir() {
			os.MkdirAll(path, f.Mode())
		} else {
			os.MkdirAll(filepath.Dir(path), f.Mode())
			f, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, f.Mode())
			if err != nil {
				return err
			}
			defer func() {
				if err := f.Close(); err != nil {
					panic(err)
				}
			}()

			_, err = io.Copy(f, rc)
			if err != nil {
				return err
			}
		}
		return nil
	}

	for _, f := range r.File {
		err := extractAndWriteFile(f)
		if err != nil {
			return err
		}
	}

	return nil
}

// http://www.rechtsprechung-im-internet.de/jportal/portal/t/tjr/page/bsjrsprod.psml/js_peid/Suchportlet1?action=portlets.jw.MainAction&eventSubmit_doNavigate=searchInSubtree&p1=bverfg
// http://www.rechtsprechung-im-internet.de/jportal/portal/t/tju/page/bsjrsprod.psml/js_peid/Suchportlet1?action=portlets.jw.MainAction&eventSubmit_doNavigate=searchInSubtree&p1=bgh
// http://www.rechtsprechung-im-internet.de/jportal/portal/t/tk9/page/bsjrsprod.psml/js_peid/Suchportlet1?action=portlets.jw.MainAction&eventSubmit_doNavigate=searchInSubtree&p1=bverwg
// http://www.rechtsprechung-im-internet.de/jportal/portal/t/tkx/page/bsjrsprod.psml/js_peid/Suchportlet1?action=portlets.jw.MainAction&eventSubmit_doNavigate=searchInSubtree&p1=bfh
// http://www.rechtsprechung-im-internet.de/jportal/portal/t/tlf/page/bsjrsprod.psml/js_peid/Suchportlet1?action=portlets.jw.MainAction&eventSubmit_doNavigate=searchInSubtree&p1=bag
// http://www.rechtsprechung-im-internet.de/jportal/portal/t/tm3/page/bsjrsprod.psml/js_peid/Suchportlet1?action=portlets.jw.MainAction&eventSubmit_doNavigate=searchInSubtree&p1=bsg
// http://www.rechtsprechung-im-internet.de/jportal/portal/t/tmh/page/bsjrsprod.psml/js_peid/Suchportlet1?action=portlets.jw.MainAction&eventSubmit_doNavigate=searchInSubtree&p1=bpatg
// http://www.rechtsprechung-im-internet.de/jportal/portal/t/tnz/page/bsjrsprod.psml/js_peid/Suchportlet1?action=portlets.jw.MainAction&eventSubmit_doNavigate=searchInSubtree&p1=gmsogb

// http://www.rechtsprechung-im-internet.de/jportal/portal/t/tpn/page/bsjrsprod.psml/js_peid/Trefferliste/media-type/html?action=portlets.jw.ResultListFormAction&tl=true&IGNORE=true&currentNavigationPosition=26&numberofresults=2707&sortmethod=date&sortiern=OK&eventSubmit_doSkipback=1&forcemax=0001
// http://www.rechtsprechung-im-internet.de/jportal/portal/t/tph/page/bsjrsprod.psml/js_peid/Trefferliste/media-type/html?action=portlets.jw.ResultListFormAction&tl=true&IGNORE=true&currentNavigationPosition=1&numberofresults=2707&sortmethod=date&sortiern=OK&eventSubmit_doSkipforward=1&forcemax=0001
// http://www.rechtsprechung-im-internet.de/jportal/portal/t/ttz/page/bsjrsprod.psml/js_peid/Trefferliste/media-type/html?action=portlets.jw.ResultListFormAction&tl=true&IGNORE=true&currentNavigationPosition=26&numberofresults=2707&sortmethod=date&sortiern=OK&eventSubmit_doSkipforward=1&forcemax=0001
// http://www.rechtsprechung-im-internet.de/jportal/portal/t/tu2/page/bsjrsprod.psml/js_peid/Trefferliste/media-type/html?action=portlets.jw.ResultListFormAction&tl=true&IGNORE=true&currentNavigationPosition=51&numberofresults=2707&sortmethod=date&sortiern=OK&eventSubmit_doSkipforward=1&forcemax=0001
