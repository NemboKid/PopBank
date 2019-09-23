import React from "react";
import { Router, Route, IndexRoute, hashHistory } from "react-router";
import ReactDOM from "react-dom";
import Link from "react-router";

import Layout from "./App.js";
import Settings from "./Settings.js";

const app = document.getElementById('app');

reactDOM.render(
  <Router history={hashHistory}>
    <Route path="/" component={Layout}>
    <Route path="settings" component={Settings}></Route>
  </Route>
  </Router>
)
