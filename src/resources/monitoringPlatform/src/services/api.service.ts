import {Injectable} from '@angular/core';
import {HttpClient} from "@angular/common/http";
import {environment} from "../environments/environment";


@Injectable({
  providedIn: 'root'
})
export class ApiService {

  constructor(public httpClient: HttpClient) {
  }

  url(addr: string) {
    return environment.apiUrl + addr;
  }

  async getListOfDatastreams(thingName: string) {
    return this.httpClient.get<any>(this.url('/' + thingName + '/properties/datastreamsList'), {});
  }

  async getMeasuresOfDatastream(thingName: string, datastreamName: string) {
    return this.httpClient.get<any>(this.url('/' + thingName + '/properties/datastreamMeasures?name=' + datastreamName), {});
  }

  async getTimeRangeMeasuresOfDatastream(thingName: string, datastreamName: string, startTime: string, endTime: string, perPageItems: number, pageNumber: number) {
    let wot_url = '/' + thingName + '/properties/datastreamTimeRangeMeasures?name=' + datastreamName;
    if (startTime !== ""){
      wot_url = wot_url + "&start_time=" + startTime;
    }
    if (endTime !== ""){
      wot_url = wot_url + "&end_time=" + endTime;
    }
    wot_url = wot_url + "&items=" + perPageItems + "&page=" + pageNumber;
    return this.httpClient.get<any>(this.url(wot_url), {});
  }

  getAllThings() {
    return this.httpClient.get<string[]>(this.url(""), {});
  }

  getThingDescription(thingUrl: string) {
    return this.httpClient.get<object>(this.url("/"+ thingUrl), {})
  }

  getFieldInformation(thingUrl: string) {
    return this.httpClient.get<object>(this.url("/"+ thingUrl + "/properties/fieldInformation"), {})
  }

  getStationInformation(thingUrl: string) {
    return this.httpClient.get<object>(this.url("/"+ thingUrl + "/properties/stationInformation"), {})
  }
}
