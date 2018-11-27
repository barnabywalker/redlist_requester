# Red List requester

This is an app using the `rredlist` package to scrape info from the [IUCN Red List API](http://apiv3.iucnredlist.org/).

## Use

At the moment the app lets you paste a list of species into a textbox and request details of the assessments for these species, from [this API endpoint](http://apiv3.iucnredlist.org/api/v3/docs#species-individual-name).

For the app to work, you need to create a `config.R` file to store an API key, with the contents:
```
TOKEN <- my_token
```
To get a token, you need to [request on from the Red List website](http://apiv3.iucnredlist.org/api/v3/token).


