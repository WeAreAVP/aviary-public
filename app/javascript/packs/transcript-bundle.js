import ReactOnRails from "react-on-rails";

import Transcript from "../bundles/Transcript/components/Transcript";
// import TranscriptEditor from "@bbc/react-transcript-editor";
// This is how react_on_rails can see the Transcript in the browser.
ReactOnRails.register({
  Transcript,
});
