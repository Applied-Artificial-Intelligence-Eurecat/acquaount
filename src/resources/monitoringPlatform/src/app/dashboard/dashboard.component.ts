import {Component, OnInit} from '@angular/core';
import {ButtonModule} from "primeng/button";
import {InputNumberModule} from "primeng/inputnumber";
import {DropdownModule} from "primeng/dropdown";
import {FormsModule} from "@angular/forms";
import {provideAnimations} from "@angular/platform-browser/animations";
import {CommonModule} from "@angular/common";
import {CalendarModule} from "primeng/calendar";
import {CheckboxModule} from "primeng/checkbox";
import {ApiService} from "../../services/api.service";
import {map} from "rxjs/operators";
import {HttpClientModule} from "@angular/common/http";
import {ChartModule} from "primeng/chart";
import {TreeSelectModule} from "primeng/treeselect";
import {ProgressBarModule} from "primeng/progressbar";
import {CardModule} from "primeng/card";
import {saveAs} from "file-saver";


@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [
    ButtonModule,
    DropdownModule,
    InputNumberModule,
    FormsModule,
    CommonModule,
    CalendarModule,
    CheckboxModule,
    ChartModule,
    TreeSelectModule,
    ProgressBarModule,
    CardModule
  ],
  providers: [
    provideAnimations(),
    HttpClientModule
  ],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss'
})
export class DashboardComponent implements OnInit {
  start_date: Date | undefined;
  end_date: Date | undefined;

  perPageItems: number = 100;
  pageNumber: number = 0;

  selected_pilot: string = "";

  pilots: {}[] = [
    {name: 'Demo'},
    {name: 'Italy'},
    {name: 'Jordan'},
    {name: 'Tunisia'},
    {name: 'Lebanon'},
    {name: 'Custom'}
  ]
  colors = [
    "#FF0000", // Red
    "#00FF00", // Green
    "#0000FF", // Blue
    "#FFFF00", // Yellow
    "#FF00FF", // Magenta
    "#00FFFF", // Cyan
    "#800080", // Purple
    "#008080", // Teal
    "#FFA500", // Orange
    "#808080"  // Gray
  ];


  constructor(public apiService: ApiService) {

  }

  nodes: any[] = [];
  selectedNodes: any[] = [];

  leafNodes: any[] = [];

  datasets: any[] = [];
  timestamps: any[] = [];

  hasData: boolean = false;
  hasChecked: boolean = false;

  options = {}
  data = {
    labels: this.timestamps,
    datasets: this.datasets
  };

  fields: Map<string, any> = new Map<string, any>;
  stations: Map<string, any> = new Map<string, any>;
  basinDemand: Map<string, any> = new Map<string, any>;
  basinResource: Map<string, any> = new Map<string, any>;

  async ngOnInit() {
    this.fields.set("Demo", []);
    this.fields.set("Italy", []);
    this.fields.set("Jordan", []);
    this.fields.set("Lebanon", []);
    this.fields.set("Tunisia", []);
    this.fields.set("Custom", []);

    this.stations.set("Demo", []);
    this.stations.set("Italy", []);
    this.stations.set("Jordan", []);
    this.stations.set("Lebanon", []);
    this.stations.set("Tunisia", []);
    this.stations.set("Custom", []);

    this.basinResource.set("Demo", []);
    this.basinResource.set("Italy", []);
    this.basinResource.set("Jordan", []);
    this.basinResource.set("Lebanon", []);
    this.basinResource.set("Tunisia", []);
    this.basinResource.set("Custom", []);

    this.basinDemand.set("Demo", []);
    this.basinDemand.set("Italy", []);
    this.basinDemand.set("Jordan", []);
    this.basinDemand.set("Lebanon", []);
    this.basinDemand.set("Tunisia", []);
    this.basinDemand.set("Custom", []);

    this.apiService.getAllThings().subscribe(v => {
      v.forEach(t => {
        let split_thing = t.split("/")
        let thingUrl = split_thing[split_thing.length - 1];

        this.apiService.getThingDescription(thingUrl).subscribe(td => {
          let label: string;
          // @ts-ignore
          let title: string = td["title"];

          // @ts-ignore
          let thingType: string = td["thingType"];

          if (thingType === "Field") {
            // @ts-ignore
            label = td["fieldName"];

            this.apiService.getFieldInformation(thingUrl).subscribe(info => {
              // @ts-ignore
              let newArr = [...this.fields.get(info["pilot"]), {
                "label": label,
                "thingName": title
              }];
              // @ts-ignore
              this.fields.set(info["pilot"], newArr);
            }, error => {

            });
          } else if (thingType === "Station") {
            // @ts-ignore
            label = td["stationName"];

            this.apiService.getStationInformation(thingUrl).subscribe(info => {
              // @ts-ignore
              let newArr = [...this.stations.get(info["pilot"]), {
                "label": label,
                "thingName": title
              }];
              // @ts-ignore
              this.stations.set(info["pilot"], newArr);
            }, error => {

            });
          } else if (thingType === "BasinWaterDemand") {
            // @ts-ignore
            label = td["itemName"];

            this.apiService.getFieldInformation(thingUrl).subscribe(info => {
              // @ts-ignore
              let newArr = [...this.basinDemand.get(info["pilot"]), {
                "label": label,
                "thingName": title
              }];
              // @ts-ignore
              this.basinDemand.set(info["pilot"], newArr);
            }, error => {

            });
          } else if (thingType === "BasinWaterResource") {
            // @ts-ignore
            label = td["itemName"];

            this.apiService.getFieldInformation(thingUrl).subscribe(info => {
              // @ts-ignore
              let newArr = [...this.basinResource.get(info["pilot"]), {
                "label": label,
                "thingName": title
              }];
              // @ts-ignore
              this.basinResource.set(info["pilot"], newArr);
            }, error => {

            });
          }
        })
      })
    })
  }

  showNodes() {
    this.hasChecked = false;
    this.calculateLeafs();
  }

  extraNodes: number = 0;

  calculateLeafs() {
    this.leafNodes = [];
    this.selectedNodes.forEach(node => {
      if (!Object.keys(node).includes("children")) {
        this.leafNodes.push(node);
      }
    });

    this.extraNodes = 0;
    if (this.leafNodes.length > 10) {
      this.extraNodes = this.leafNodes.length - 10;
      this.leafNodes = this.leafNodes.slice(0, 10);
    }
  }

  clearNodes() {
    this.selectedNodes = [];
    this.leafNodes = [];

    this.extraNodes = 0;

    this.timestamps = [];
    this.datasets = [];

    this.hasData = false;

    this.data = {
      labels: this.timestamps,
      datasets: this.datasets
    };
  }

  async updateDatastreamsDependingOnPilot() {

    //

    let currentFields: { thingName: string; label: string }[] = this.fields.get(this.selected_pilot);
    let currentStations: { thingName: string; label: string }[] = this.stations.get(this.selected_pilot);
    let currentDemand: { thingName: string; label: string }[] = this.basinDemand.get(this.selected_pilot);
    let currentResource: { thingName: string; label: string }[] = this.basinResource.get(this.selected_pilot);

    //

    let fieldsAndDatastreams: any[] = [];
    for (let i = 0; i < currentFields.length; i++) {
      let field = currentFields[i];
      let obs = await this.apiService.getListOfDatastreams(field['thingName'].toLowerCase()).then(
        map(response => {
          return response;
        })
      );
      obs.subscribe(
        (res) => {
          let fieldChildren: any[] = [];

          for (let j = 0; j < res.length; j++) {
            fieldChildren.push({
              "label": res[j]["name"],
              "thingName": field['thingName'].toLowerCase()
            });
          }

          fieldsAndDatastreams.push({
            "label": field['label'],
            "thingName": field['thingName'].toLowerCase(),
            "icon": "pi pi-map",
            "children": fieldChildren
          });
        }
      );
    }

    let stationsAndDatastreams: any[] = [];
    for (let i = 0; i < currentStations.length; i++) {
      let field = currentStations[i];
      let obs = await this.apiService.getListOfDatastreams(field['thingName'].toLowerCase()).then(
        map(response => {
          return response;
        })
      );
      obs.subscribe(
        (res) => {
          let fieldChildren: any[] = [];

          for (let j = 0; j < res.length; j++) {
            fieldChildren.push({
              "label": res[j]["name"],
              "thingName": field['thingName'].toLowerCase()
            });
          }

          stationsAndDatastreams.push({
            "label": field['label'],
            "thingName": field['thingName'].toLowerCase(),
            "icon": "pi pi-map",
            "children": fieldChildren
          });
        }
      );
    }

    let demandAndDatastreams: any[] = [];
    for (let i = 0; i < currentDemand.length; i++) {
      let field = currentDemand[i];
      let obs = await this.apiService.getListOfDatastreams(field['thingName'].toLowerCase()).then(
        map(response => {
          return response;
        })
      );
      obs.subscribe(
        (res) => {
          let fieldChildren: any[] = [];

          for (let j = 0; j < res.length; j++) {
            fieldChildren.push({
              "label": res[j]["name"],
              "thingName": field['thingName'].toLowerCase()
            });
          }

          demandAndDatastreams.push({
            "label": field['label'],
            "thingName": field['thingName'].toLowerCase(),
            "icon": "pi pi-map",
            "children": fieldChildren
          });
        }
      );
    }

    let resourceAndDatastreams: any[] = [];
    for (let i = 0; i < currentResource.length; i++) {
      let field = currentResource[i];
      let obs = await this.apiService.getListOfDatastreams(field['thingName'].toLowerCase()).then(
        map(response => {
          return response;
        })
      );
      obs.subscribe(
        (res) => {
          let fieldChildren: any[] = [];

          for (let j = 0; j < res.length; j++) {
            fieldChildren.push({
              "label": res[j]["name"],
              "thingName": field['thingName'].toLowerCase()
            });
          }

          resourceAndDatastreams.push({
            "label": field['label'],
            "thingName": field['thingName'].toLowerCase(),
            "icon": "pi pi-map",
            "children": fieldChildren
          });
        }
      );
    }

    this.nodes = [
      {
        label: "Fields",
        children: fieldsAndDatastreams
      }, {
        label: "Weather Stations",
        children: stationsAndDatastreams
      }, {
        label: "Basin",
        children: [{
          label: "Water Resource",
          children: resourceAndDatastreams
        },{
          label: "Water Demand",
          children: demandAndDatastreams
        }]
      }
    ];

    this.calculateLeafs();
  }

  async updateGraph() {
    let new_timestamps: any[] = [];
    let new_datasets: any[] = [];

    this.hasChecked = true;

    let startTime = "";
    let endTime = "";
    if (this.start_date !== null && this.start_date !== undefined) {
      startTime = this.formatDateToUTCString(this.start_date);
    }
    if (this.end_date !== null && this.end_date !== undefined) {
      endTime = this.formatDateToUTCString(this.end_date);
    }

    console.log("Button pressed");
    console.log(this.leafNodes);

    let colorIndex = 0;
    for (const node of this.leafNodes) {
      console.log(node);
      if (!Object.keys(node).includes("children")) {
        console.log("Valid node");
        let obs = await this.apiService.getTimeRangeMeasuresOfDatastream(node["thingName"], node["label"], startTime, endTime, this.perPageItems, this.pageNumber).then(
          map(response => {
            console.log("Returning a response");
            return response;
          })
        );
        obs.subscribe(
          (res) => {
            console.log("Result received");
            console.log(res);
            res.forEach((m: any) => {
              let time = this.parseDateString(m["time_of_measure"]);
              if (!new_timestamps.includes(this.formatDateToString(time))) {
                new_timestamps.push(this.formatDateToString(time));
              }
            });
            new_timestamps.sort();
            let new_data: any[] = [];
            new_timestamps.forEach((t: any) => {
              let found = -1;
              let ind = 0;
              for (let measure of res) {
                if (this.formatDateToString(this.parseDateString(measure["time_of_measure"])) === t) {
                  new_data.push(measure["value"]);
                  found = ind;
                  break;
                }
                ind += 1;
              }
              if (found === -1) {
                new_data.push(NaN);
              }
            });
            let color = this.colors[colorIndex % 10];
            let filledOrNot = (colorIndex / 10) % 3 == 2;
            let border: number = 0;
            if ((colorIndex / 10) % 3 == 1) {
              border = 5;
            }

            colorIndex += 1;

            let new_dataset = {
              label: node["label"],
              data: new_data,
              fill: filledOrNot,
              borderColor: color,
              borderDash: [border],
              tension: 0.3
            }
            new_datasets.push(new_dataset);
            this.timestamps = [];
            new_timestamps.forEach((t) => {
              this.timestamps.push(t);
            })

            this.datasets = new_datasets;

            this.data = {
              labels: this.timestamps,
              datasets: this.datasets
            };
            this.hasData = true;
          }
        );
      }
    }
  }

  parseDateString(dateString: string) {
    // Parse the string into its components
    // @ts-ignore
    const [year, month, day, hours, minutes, seconds] = dateString.match(/\d+/g).map(Number);

    // Create a new Date object
    return new Date(Date.UTC(year, month - 1, day, hours, minutes, seconds));
  }

  formatDateToString(date: Date) {
    // Get individual components
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");
    const hours = String(date.getHours()).padStart(2, "0");
    const minutes = String(date.getMinutes()).padStart(2, "0");
    const seconds = String(date.getSeconds()).padStart(2, "0");

    // Format the date string
    return `${year}-${month}-${day}T${hours}:${minutes}:${seconds}`;
  }

  formatDateToUTCString(date: Date) {
    // Get individual components
    const year = date.getUTCFullYear();
    const month = String(date.getUTCMonth() + 1).padStart(2, "0");
    const day = String(date.getUTCDate()).padStart(2, "0");
    const hours = String(date.getUTCHours()).padStart(2, "0");
    const minutes = String(date.getUTCMinutes()).padStart(2, "0");
    const seconds = String(date.getUTCSeconds()).padStart(2, "0");

    // Format the date string
    return `${year}-${month}-${day}T${hours}:${minutes}:${seconds}Z`;
  }

  exportCSV() {
    let headers = ['Timestamp'];
    this.data.datasets.forEach(dataset => {
      headers.push(dataset.label);
    });

    const data = [headers];

    this.data.labels.forEach(timestamp => {
      let row: string[] = [timestamp];
      this.data.datasets.forEach(dataset => {
        let value = dataset.data[this.data.labels.indexOf(timestamp)];
        row.push(value);
      });
      data.push(row);
    })

    // Convert the data array to CSV format
    const csvContent = data.map(row => row.join(',')).join('\n');

    // Create a Blob containing the CSV data
    const blob = new Blob([csvContent], {type: 'text/csv;charset=utf-8'});

    // Trigger the file download
    saveAs(blob, 'export.csv');
  }
}
