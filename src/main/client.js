Servient = require("@node-wot/core").Servient;
HttpClientFactory = require("@node-wot/binding-http").HttpClientFactory;

Helpers = require("@node-wot/core").Helpers;

// create Servient and add HTTP binding
let servient = new Servient();
servient.addClientFactory(new HttpClientFactory(null));

let wotHelper = new Helpers(servient);
wotHelper.fetch("http://127.0.0.1:8080/acquaountthingdemosite")
    .then(async (td) => {
        try {
            const WoT = await servient.start();
            const thing = await WoT.consume(td);

            // read property
            const read1 = await thing.readProperty("fieldInformation");
            console.log("string value is: ", await read1.value());
            thing.subscribeEvent("newObservation", async (data) => {
                console.log("New observation event:", await data.value());
            });
        } catch (err) {
            console.error("Script error:", err);
        }
    })
    .catch((err) => {
        console.error("Fetch error:", err);
    });