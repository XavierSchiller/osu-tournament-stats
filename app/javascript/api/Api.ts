import { ContentType } from "./Constants";
import { IRequest } from "./IRequest";
import RequestError from "./RequestError";

export default class Api {
  public static async performRequest<P>({ url, payload, options }: IRequest): Promise<P> {
    const headers = {
      ...options.headers || {},
      "Accept": ContentType.Json,
      "Content-Type": ContentType.Json,
    };

    let body: string = null;

    if (payload !== null) {
      body = JSON.stringify(payload);
    }

    return this.performRequestInternal<P>(url, body, { ...options, headers });
  }

  private static async performRequestInternal<P>(url: string, body: any, options: RequestInit): Promise<P> {
    // TODO: set up the request here first with auth headers and whatnot

    const opts: RequestInit = {
      ...options || {},
      credentials: "same-origin",
      mode: "same-origin",
    };

    if (body !== null) {
      opts.body = body;
    }

    try {
      const response = await fetch(url, opts);

      if (response.status >= 400) {
        const json = this.tryGetJson(await response.text());

        throw new RequestError((json && json.error) || "An error occurred!", response.status, (json && json.code) || null);
      }

      if (response.status >= 300) {
        throw new RequestError("Request resulted in a redirect!", response.status);
      }

      console.debug(`Request to ${url} succcessfully completed!`);

      return this.tryGetJson(await response.text());
    } catch (e) {
      console.error(`Request to ${url} failed!`);

      if (e.code === "AbortError") {
        throw new RequestError("Request cancelled!", 0, e.code);
      }

      if (e instanceof RequestError) {
        throw e;
      }

      throw new RequestError("An error occurred!");
    }
  }

  private static tryGetJson(text: string): any {
    try {
      return JSON.parse(text);
    } catch {}
  }
}
