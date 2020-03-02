import React, { Component } from 'react';
import './App.css';
import PMTable from './PMTable.js';

class App extends Component {

  constructor(props) {
    super(props);
    this.state = {
      data: {
        members: [],
        households: [],
      },
      currentView: 'members',
      usePagination: true
    }
  }

  componentDidMount() {
    this.loadData();
  }

  loadData() {
    fetch('/Members/readAll', {
      credentials: 'include',
      mode: 'cors'
    })
    .then(res => {
      res.json()
      .then(json => {
        this.setState(prevState => {
          let data = prevState.data;
          data.members = json.map(x => x.value);;
          return {data}
          });
      });
    });

    fetch('/Households/readAll', {
      credentials: 'include',
      mode: 'cors'
    })
    .then(res => {
      res.json()
      .then(json => {
        this.setState(prevState => {
          let data = prevState.data;
          data.hoouseholds = json.map(x => x.value);
          return {data}
          });
      });
    });
  }

  render() {
    return (
      <div className="App">
        <div >
          <h2>Peri Meleon Demo</h2>
        </div>
        <div id="paginate">
          <input type="checkbox"
            onClick={(e) => this.setState({usePagination: e.target.checked})}
            defaultChecked={this.state.usePagination}
          />Paginate
        </div>
        <PMTable
          data={this.state.data[this.state.currentView]}
          usePagination={this.state.usePagination}
        />
      </div>
    );
  }
}

export default App;
