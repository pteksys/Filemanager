/*
 * Copyright (C) 2012 Robin Burchell <robin+nemo@viroteck.net>
 *
 * You may use this file under the terms of the BSD license as follows:
 *
 * "Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *   * Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in
 *     the documentation and/or other materials provided with the
 *     distribution.
 *   * Neither the name of Nemo Mobile nor the names of its contributors
 *     may be used to endorse or promote products derived from this
 *     software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
 */

#ifndef DIRMODEL_H
#define DIRMODEL_H

#include <QAbstractListModel>
#include <QFileInfo>
#include <QVector>
#include <QStringList>

#include "iorequest.h"

class FileSystemAction;

class DirModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum Roles {
        FileNameRole = Qt::UserRole,
        CreationDateRole,
        ModifiedDateRole,
        FileSizeRole,
        IconSourceRole,
        FilePathRole,
        IsDirRole,
        IsFileRole,
        IsReadableRole,
        IsWritableRole,
        IsExecutableRole
    };

public:
    DirModel(QObject *parent = 0);
    ~DirModel();

    int rowCount(const QModelIndex &index = QModelIndex()) const
    {
        if (index.parent() != QModelIndex())
            return 0;
        return mDirectoryContents.count();
    }

#if defined(REGRESSION_TEST_FOLDERLISTMODEL)
    //make this work with tables
    int columnCount(const QModelIndex &) const
    {
        return IsExecutableRole - FileNameRole + 1;
    }
    QVariant  headerData(int section, Qt::Orientation orientation, int role) const;
#endif

    // TODO: this won't be safe if the model can change under the holder of the row
    Q_INVOKABLE QVariant data(int row, const QByteArray &stringRole) const;

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;

    Q_INVOKABLE void refresh()
    {
        // just some syntactical sugar really
        setPath(path());
    }

    Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged)
    inline QString path() const { return mCurrentDir; }

    Q_PROPERTY(bool awaitingResults READ awaitingResults NOTIFY awaitingResultsChanged)
    bool awaitingResults() const;

    void setPath(const QString &pathName);

    Q_INVOKABLE void rm(const QStringList &paths);

    Q_INVOKABLE bool rename(int row, const QString &newName);

    Q_INVOKABLE void mkdir(const QString &newdir);

    Q_PROPERTY(bool showDirectories READ showDirectories WRITE setShowDirectories NOTIFY showDirectoriesChanged)
    bool showDirectories() const;
    void setShowDirectories(bool showDirectories);

    Q_PROPERTY(QStringList nameFilters READ nameFilters WRITE setNameFilters NOTIFY nameFiltersChanged)
    QStringList nameFilters() const;
    void setNameFilters(const QStringList &nameFilters);


public slots:
    void onItemsAdded(const QVector<QFileInfo> &newFiles);

signals:
    void awaitingResultsChanged();
    void nameFiltersChanged();
    void showDirectoriesChanged();
    void pathChanged(const QString& newPath);
    void error(const QString &errorTitle, const QString &errorMessage);

public:
#if QT_VERSION < QT_VERSION_CHECK(5, 0, 0)
    // There's no virtual roleNames in Qt4. Proxy returns the role names
    // that are initialized in constructor.
    QHash<int, QByteArray> proxyRoleNames() const;
#else
    // In Qt5, the roleNames() is virtual and will work just fine.
    QHash<int, QByteArray> roleNames() const;
#endif

//[0] new stuff Ubuntu File Manager
    /*!
     *    \brief Tries to make the directory pointed by row as the current to be browsed
     *    \return true if row points to a directory and the directory is readble, false otherwise
     */
    Q_INVOKABLE  bool cdInto(int row);

    /*!
     * \brief copy() puts the item pointed by \a row (dir or file) into the clipboard
     * \param row points to the item file or directory
     */
    Q_INVOKABLE void  copy(int row);

    /*!
     *  \brief copy(const QStringList& urls) several items (dirs or files) into the clipboard
     *  \param items  fullpathnames or names only
     */
    Q_INVOKABLE void  copy(const QStringList& items);

    /*!
     * \brief cut() puts the item into the clipboard as \ref copy(),
     *        mark the item to be removed after \ref paste()
     * \param row points to the item file or directory
     */   
    Q_INVOKABLE void  cut(int row);

    /*!
     *  \brief cut() puts several items (dirs or files) into the clipboard as \ref copy(),
     *         mark the item to be removed after \ref paste()
     *   \param items  fullpathnames or names only
     */
    Q_INVOKABLE void  cut(const QStringList& items);

    /*!
     * \brief remove()  remove a item file or directory
     *
     * I gets the item indicated by \row and calls \ref rm()
     *
     * \param row points to the item to b e removed
     * \return true if it was possible to remove the item
     */
    Q_INVOKABLE void remove(int row);

    /*!
     *  Just calls \ref rm()
     */
    Q_INVOKABLE void remove(const QStringList& items);


public slots:
    /*!
     * \brief goHome() goes to user home dir
     *  Go to user home dir, we may have a tab for places or something like that
     */
    void  goHome();

    /*!
     * \brief cdUp() sets the parent directory as current directory
     *
     *  It can work as a back function if there is no user input path
     * \return true if it was possible to change to parent dir, otherwise false
     */
    bool  cdUp();

    /*!
     * \brief paste() copy item(s) from \ref copy() and \ref paste() into the current directory
     *
     *  If the operation was \ref cut(), then remove the original item
     */
    void paste();

    /*!
     * \brief cancelAction() any copy/cut/remove can be cancelled
     */
    void cancelAction();

signals:
    /*!
     * \brief insertedItem()
     *
     *  It happens when a new file is inserted in a existent view,
     *  for example from  \ref mkdir() or \ref paste()
     *
     *  It can be used to make the new row visible to the user doing a scroll to
     */
    void  insertedRow(int row);
    /*!
     * \brief progress()
     *  Sends status about recursive and multi-items remove/move/copy
     *
     * \param curItem     current item being handled
     * \param totalItems  total of items including recursive directories content
     * \param percent     a percent done
     */
    void     progress(int curItem, int totalItems, int percent);

private slots:
    void onItemRemoved(const QString&);
    void onItemRemoved(const QFileInfo&);
    void onItemAdded(const QString&);
    void onItemAdded(const QFileInfo&);

private:
    int  addItem(const QFileInfo& fi);

#if defined(REGRESSION_TEST_FOLDERLISTMODEL) //used in Unit/Regression tests
public:
#else
private:
#endif
    FileSystemAction  *  m_fsAction;  //!< it does file system recursive remove/copy/move
    QString fileSize(qint64 size)  const;
//[0]

 private:
    QStringList mNameFilters;
    bool mShowDirectories;
    bool mAwaitingResults;
    QString mCurrentDir;
    QVector<QFileInfo> mDirectoryContents;
    QHash<QByteArray, int> mRoleMapping;
};


#endif // DIRMODEL_H
