import React from 'react'
import styled from 'styled-components'
import { useTable, usePagination } from 'react-table'


const Styles = styled.div`
  padding: 1rem;

  table {
    margin auto;
    border-spacing: 0;
    border: 1px solid black;

    tr {
      :last-child {
        td {
          border-bottom: 0;
        }
      }
    }

    th,
    td {
      margin: 0;
      padding: 0.5rem;
      border-bottom: 1px solid black;
      border-right: 1px solid black;

      :last-child {
        border-right: 0;
      }
    }
  }

  .pagination {
    padding: 0.5rem;
    margin: 0
  }
`

function Table({ columns, data, showPagination }) {
    
  const {
    getTableProps,
    getTableBodyProps,
    headerGroups,
    prepareRow,
    page,
    rows,
    canPreviousPage,
    canNextPage,
    pageOptions,
    pageCount,
    gotoPage,
    nextPage,
    previousPage,
    setPageSize,
    state: { pageIndex, pageSize },
  } = useTable(
    {
      columns,
      data,
      initialState: { pageIndex: 0 },
    },
    usePagination
  )

  data = showPagination ? page : rows
  return (
    <div>
    <table {...getTableProps()}>
      <thead>
        {headerGroups.map(headerGroup => (
          <tr {...headerGroup.getHeaderGroupProps()}>
            {headerGroup.headers.map(column => (
              <th {...column.getHeaderProps()}>{column.render('Header')}</th>
            ))}
          </tr>
        ))}
      </thead>
      <tbody {...getTableBodyProps()}>
        {data.map((row, i) => {
          prepareRow(row)
          return (
            <tr {...row.getRowProps()}>
              {row.cells.map(cell => {
                return <td {...cell.getCellProps()}>{cell.render('Cell')}</td>
              })}
            </tr>
          )
        })}
      </tbody>
    </table>
    {showPagination ?
    <div className="pagination">
        <button onClick={() => gotoPage(0)} disabled={!canPreviousPage}>
          {'<<'}
        </button>{' '}
        <button onClick={() => previousPage()} disabled={!canPreviousPage}>
          {'<'}
        </button>{' '}
        <button onClick={() => nextPage()} disabled={!canNextPage}>
          {'>'}
        </button>{' '}
        <button onClick={() => gotoPage(pageCount - 1)} disabled={!canNextPage}>
          {'>>'}
        </button>{' '}
        <span>
          Page{' '}
          <strong>
            {pageIndex + 1} of {pageOptions.length}
          </strong>{' '}
        </span>
        <span>
          | Go to page:{' '}
          <input
            type="number"
            defaultValue={pageIndex + 1}
            onChange={e => {
              const page = e.target.value ? Number(e.target.value) - 1 : 0
              gotoPage(page)
            }}
            style={{ width: '100px' }}
          />
        </span>{' '}
        <select
          value={pageSize}
          onChange={e => {
            setPageSize(Number(e.target.value))
          }}
        >
          {[10, 20, 30, 40, 50].map(pageSize => (
            <option key={pageSize} value={pageSize}>
              Show {pageSize}
            </option>
          ))}
        </select>
      </div> : null}
      </div>
  )
}

function PMTable(props) {
  const columns = React.useMemo(
    () => [
        {
            Header: 'Name',
            accessor: rec => `${rec.givenName} ${rec.familyName}`
        },
        {
            Header: 'Address',
            accessor: rec => 'Somewhere'
        },
        {
            Header: 'Phone Number',
            accessor: 'mobilePhone'
        },
        {
            Header: 'EMail',
            accessor: 'eMail',
        },
        {
            Header: 'Status',
            accessor: 'status',
        },
        {
            Header: 'Resident',
            accessor: rec => rec.resident ? 'Yes': 'No'
        },
    ],
    []
  )

//   const data = React.useMemo(() => props.data, [])

  return (
    <Styles>
      <Table
        columns={columns}
        data={props.data}
        showPagination={props.usePagination}
      />
    </Styles>
  )
}

export default PMTable
